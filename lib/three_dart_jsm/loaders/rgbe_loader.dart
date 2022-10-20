import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart';

// https://github.com/mrdoob/three.js/issues/5552
// http://en.wikipedia.org/wiki/RGBE_image_format

class RGBELoader extends DataTextureLoader {
  int type = HalfFloatType;

  RGBELoader(manager) : super(manager);

  // adapted from http://www.graphics.cornell.edu/~bjw/rgbe.html

  @override
  parse(json, [String? path, Function? onLoad, Function? onError]) {
    int byteArrayPos = 0;

    const
        /* return codes for rgbe routines */
        //RGBE_RETURN_SUCCESS = 0,
        rgbeReturnFailure = -1,

        /* default error routine.  change this to change error handling */
        rgbeReadError = 1,
        rgbeWriteError = 2,
        rgbeFormatError = 3,
        rgbeMemoryError = 4;

    rgbeError(rgbeErrorCode, msg) {
      switch (rgbeErrorCode) {
        case rgbeReadError:
          print('THREE.RGBELoader Read Error: ${msg ?? ""}');
          break;
        case rgbeWriteError:
          print('THREE.RGBELoader Write Error: ${msg ?? ""}');
          break;
        case rgbeFormatError:
          print('THREE.RGBELoader Bad File Format: ${msg ?? ""}');
          break;
        case rgbeMemoryError:
          print('THREE.RGBELoader: Error: ${msg ?? ""}');
          break;
        default:
      }

      return rgbeReturnFailure;
    }

    /* offsets to red, green, and blue components in a data (float) pixel */
    //RGBE_DATA_RED = 0,
    //RGBE_DATA_GREEN = 1,
    //RGBE_DATA_BLUE = 2,

    /* number of floats per pixel, use 4 since stored in rgba image format */
    //RGBE_DATA_SIZE = 4,

    /* flags indicating which fields in an rgbe_header_info are valid */
    var rgbeValieProgramType = 1, rgbeValidFormat = 2, rbgValidDimensions = 4;

    var newLine = '\n';

    fgets(Uint8List buffer, [lineLimit, consume]) {
      var chunkSize = 128;

      lineLimit = lineLimit ?? 1024;
      var p = byteArrayPos;
      var i = -1;
      int len = 0;
      var s = '';
      var chunk = String.fromCharCodes(buffer.sublist(p, p + chunkSize));

      while ((0 > (i = chunk.indexOf(newLine))) && (len < lineLimit) && (p < buffer.lengthInBytes)) {
        s += chunk;
        len += chunk.length;
        p += chunkSize;
        chunk += String.fromCharCodes(buffer.sublist(p, p + chunkSize));
      }

      if (-1 < i) {
        /*for (i=l-1; i>=0; i--) {
						byteCode = m.charCodeAt(i);
						if (byteCode > 0x7f && byteCode <= 0x7ff) byteLen++;
						else if (byteCode > 0x7ff && byteCode <= 0xffff) byteLen += 2;
						if (byteCode >= 0xDC00 && byteCode <= 0xDFFF) i--; //trail surrogate
					}*/
        if (false != consume) byteArrayPos += len + i + 1;
        return s + chunk.substring(0, i);
      }

      return null;
    }

    /* minimal header reading.  modify if you want to parse more information */
    rgbeReadHeader(buffer) {
      // regexes to parse header info fields
      var magicTokenRe = RegExp(r"^#\?(\S+)"),
          gammaRe = RegExp(r"^\s*GAMMA\s*=\s*(\d+(\.\d+)?)\s*$"),
          exposureRe = RegExp(r"^\s*EXPOSURE\s*=\s*(\d+(\.\d+)?)\s*$"),
          formatRe = RegExp(r"^\s*FORMAT=(\S+)\s*$"),
          dimensionsRe = RegExp(r"^\s*\-Y\s+(\d+)\s+\+X\s+(\d+)\s*$");

      // RGBE format header struct
      Map<String, dynamic> header = {
        "valid": 0,
        /* indicate which fields are valid */

        "string": '',
        /* the actual header string */

        "comments": '',
        /* comments found in header */

        "programtype": 'RGBE',
        /* listed at beginning of file to identify it after "#?". defaults to "RGBE" */

        "format": '',
        /* RGBE format, default 32-bit_rle_rgbe */

        "gamma": 1.0,
        /* image has already been gamma corrected with given gamma. defaults to 1.0 (no correction) */

        "exposure": 1.0,
        /* a value of 1.0 in an image corresponds to <exposure> watts/steradian/m^2. defaults to 1.0 */

        "width": 0,
        "height": 0 /* image dimensions, width/height */
      };

      var match;

      var line = fgets(buffer, null, null);

      if (byteArrayPos >= buffer.lengthInBytes || line == null) {
        return rgbeError(rgbeReadError, 'no header found');
      }

      /* if you want to require the magic token then uncomment the next line */
      if (!(magicTokenRe.hasMatch(line))) {
        return rgbeError(rgbeFormatError, 'bad initial token');
      }

      match = magicTokenRe.firstMatch(line);

      int valid = header["valid"]!;

      valid |= rgbeValieProgramType;
      header["valid"] = valid;

      header["programtype"] = match[1];
      header["string"] += '$line\n';

      while (true) {
        line = fgets(buffer);
        if (null == line) break;
        header["string"] += '$line\n';

        if (line.isNotEmpty && '#' == line[0]) {
          header["comments"] += '$line\n';
          continue; // comment line

        }

        if (gammaRe.hasMatch(line)) {
          match = gammaRe.firstMatch(line);

          header["gamma"] = parseFloat(match[1]);
        }

        if (exposureRe.hasMatch(line)) {
          match = exposureRe.firstMatch(line);

          header["exposure"] = parseFloat(match[1]);
        }

        if (formatRe.hasMatch(line)) {
          match = formatRe.firstMatch(line);

          header["valid"] |= rgbeValidFormat;
          header["format"] = match[1]; //'32-bit_rle_rgbe';

        }

        if (dimensionsRe.hasMatch(line)) {
          match = dimensionsRe.firstMatch(line);

          header["valid"] |= rbgValidDimensions;
          header["height"] = int.parse(match[1]);
          header["width"] = int.parse(match[2]);
        }

        if ((header["valid"] & rgbeValidFormat) == 1 && (header["valid"] & rbgValidDimensions) == 1) break;
      }

      if ((header["valid"] & rgbeValidFormat) == 0) {
        return rgbeError(rgbeFormatError, 'missing format specifier');
      }

      if ((header["valid"] & rbgValidDimensions) == 0) {
        return rgbeError(rgbeFormatError, 'missing image size specifier');
      }

      return header;
    }

    rgbeReadPixelsRLE(Uint8List buffer, int w, int h) {
      int scanlineWidth = w;

      if (
          // run length encoding is not allowed so read flat
          ((scanlineWidth < 8) || (scanlineWidth > 0x7fff)) ||
              // this file is not run length encoded
              ((2 != buffer[0]) || (2 != buffer[1]) || ((buffer[2] & 0x80) != 0))) {
        // return the flat buffer
        return buffer;
      }

      if (scanlineWidth != ((buffer[2] << 8) | buffer[3])) {
        return rgbeError(rgbeFormatError, 'wrong scanline width');
      }

      var dataRgba = Uint8List(4 * w * h);

      if (dataRgba.isEmpty) {
        return rgbeError(rgbeMemoryError, 'unable to allocate buffer space');
      }

      var offset = 0, pos = 0;

      var ptrEnd = 4 * scanlineWidth;
      var rgbeStart = Uint8List(4);
      var scanlineBuffer = Uint8List(ptrEnd);
      var numScanlines = h;

      // read in each successive scanline
      while ((numScanlines > 0) && (pos < buffer.lengthInBytes)) {
        if (pos + 4 > buffer.lengthInBytes) {
          return rgbeError(rgbeReadError, null);
        }

        rgbeStart[0] = buffer[pos++];
        rgbeStart[1] = buffer[pos++];
        rgbeStart[2] = buffer[pos++];
        rgbeStart[3] = buffer[pos++];

        if ((2 != rgbeStart[0]) || (2 != rgbeStart[1]) || (((rgbeStart[2] << 8) | rgbeStart[3]) != scanlineWidth)) {
          return rgbeError(rgbeFormatError, 'bad rgbe scanline format');
        }

        // read each of the four channels for the scanline into the buffer
        // first red, then green, then blue, then exponent
        var ptr = 0;
        int count;

        while ((ptr < ptrEnd) && (pos < buffer.lengthInBytes)) {
          count = buffer[pos++];
          var isEncodedRun = count > 128;
          if (isEncodedRun) count -= 128;

          if ((0 == count) || (ptr + count > ptrEnd)) {
            return rgbeError(rgbeFormatError, 'bad scanline data');
          }

          if (isEncodedRun) {
            // a (encoded) run of the same value
            var byteValue = buffer[pos++];
            for (var i = 0; i < count; i++) {
              scanlineBuffer[ptr++] = byteValue;
            }
            //ptr += count;

          } else {
            // a literal-run
            scanlineBuffer.setAll(ptr, buffer.sublist(pos, pos + count));
            ptr += count;
            pos += count;
          }
        }

        // now convert data from buffer into rgba
        // first red, then green, then blue, then exponent (alpha)
        var l = scanlineWidth; //scanline_buffer.lengthInBytes;
        for (var i = 0; i < l; i++) {
          var off = 0;
          dataRgba[offset] = scanlineBuffer[i + off];
          off += scanlineWidth; //1;
          dataRgba[offset + 1] = scanlineBuffer[i + off];
          off += scanlineWidth; //1;
          dataRgba[offset + 2] = scanlineBuffer[i + off];
          off += scanlineWidth; //1;
          dataRgba[offset + 3] = scanlineBuffer[i + off];
          offset += 4;
        }

        numScanlines--;
      }

      return dataRgba;
    }

    rgbeByteToRGBFloat(sourceArray, sourceOffset, destArray, destOffset) {
      var e = sourceArray[sourceOffset + 3];
      var scale = Math.pow(2.0, e - 128.0) / 255.0;

      destArray[destOffset + 0] = sourceArray[sourceOffset + 0] * scale;
      destArray[destOffset + 1] = sourceArray[sourceOffset + 1] * scale;
      destArray[destOffset + 2] = sourceArray[sourceOffset + 2] * scale;
      destArray[destOffset + 3] = 1;
    }

    rgbeByteToRGBHalf(sourceArray, sourceOffset, destArray, destOffset) {
      var e = sourceArray[sourceOffset + 3];
      var scale = Math.pow(2.0, e - 128.0) / 255.0;

      // clamping to 65504, the maximum representable value in float16
      destArray[destOffset + 0] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 0] * scale, 65504));
      destArray[destOffset + 1] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 1] * scale, 65504));
      destArray[destOffset + 2] = DataUtils.toHalfFloat(Math.min(sourceArray[sourceOffset + 2] * scale, 65504));
      destArray[destOffset + 3] = DataUtils.toHalfFloat(1.0);
    }

    // var byteArray = new Uint8Array( buffer );
    // byteArray.pos = 0;
    var byteArray = json;

    var rgbeHeaderInfo = rgbeReadHeader(byteArray);

    if (rgbeReturnFailure != rgbeHeaderInfo) {
      rgbeHeaderInfo = rgbeHeaderInfo as Map<String, dynamic>;

      var w = rgbeHeaderInfo["width"], h = rgbeHeaderInfo["height"];

      Uint8List imageRgbaData = rgbeReadPixelsRLE(byteArray.sublist(byteArrayPos), w, h) as Uint8List;

      var data, format, type;
      int numElements;

      switch (this.type) {

        // case UnsignedByteType:

        // 	data = image_rgba_data;
        // 	format = RGBEFormat; // handled as THREE.RGBAFormat in shaders
        // 	type = UnsignedByteType;
        // 	break;

        case FloatType:
          numElements = imageRgbaData.length ~/ 4;
          var floatArray = Float32Array(numElements * 4);

          for (var j = 0; j < numElements; j++) {
            rgbeByteToRGBFloat(imageRgbaData, j * 4, floatArray, j * 4);
          }

          data = floatArray;
          type = FloatType;
          break;

        case HalfFloatType:
          numElements = imageRgbaData.length ~/ 4;
          var halfArray = Uint16Array(numElements * 4);

          for (var j = 0; j < numElements; j++) {
            rgbeByteToRGBHalf(imageRgbaData, j * 4, halfArray, j * 4);
          }

          data = halfArray;
          type = HalfFloatType;
          break;

        default:
          print('THREE.RGBELoader: unsupported type: ${this.type}');
          break;
      }

      return {
        "width": w,
        "height": h,
        "data": data,
        "header": rgbeHeaderInfo["string"],
        "gamma": rgbeHeaderInfo["gamma"],
        "exposure": rgbeHeaderInfo["exposure"],
        "format": format,
        "type": type
      };
    }

    return null;
  }

  setDataType(value) {
    type = value;
    return this;
  }

  @override
  loadAsync(url) async {
    var completer = Completer();

    load(url, (result) {
      completer.complete(result);
    });

    return completer.future;
  }

  @override
  load(url, onLoad, [onProgress, onError]) {
    onLoadCallback(texture, texData) {
      switch (texture.type) {
        case UnsignedByteType:
          texture.encoding = RGBEEncoding;
          texture.minFilter = NearestFilter;
          texture.magFilter = NearestFilter;
          texture.generateMipmaps = false;
          texture.flipY = true;
          break;

        case FloatType:
          texture.encoding = LinearEncoding;
          texture.minFilter = LinearFilter;
          texture.magFilter = LinearFilter;
          texture.generateMipmaps = false;
          texture.flipY = true;
          break;

        case HalfFloatType:
          texture.encoding = LinearEncoding;
          texture.minFilter = LinearFilter;
          texture.magFilter = LinearFilter;
          texture.generateMipmaps = false;
          texture.flipY = true;
          break;
      }

      onLoad(texture);
    }

    return super.load(url, onLoadCallback, onProgress, onError);
  }
}
