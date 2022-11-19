import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart';

// https://wwwimages2.adobe.com/content/dam/acom/en/products/speedgrade/cc/pdfs/cube-lut-specification-1.0.pdf

class LUTCubeLoader extends Loader {
  LUTCubeLoader(manager) : super(manager);

  @override
  loadAsync(url) async {
    var loader = FileLoader(manager);
    loader.setPath(path);
    loader.setResponseType('text');
    final resp = await loader.loadAsync(url);

    return parse(resp);
  }

  @override
  load(url, Function onLoad, [Function? onProgress, Function? onError]) async {
    var loader = FileLoader(manager);
    loader.setPath(path);
    loader.setResponseType('text');
    final data = await loader.load(url, (text) {
      // try {
      onLoad(parse(text));
      // } catch ( e ) {

      // 	if ( onError != null ) {

      // 		onError( e );

      // 	} else {

      // 		print( e );

      // 	}

      // 	this.manager.itemError( url );

      // }
    }, onProgress, onError);

    return data;
  }

  @override
  parse(json, [String? path, Function? onLoad, Function? onError]) {
    // Remove empty lines and comments
    // str = str
    // 	.replace( /^#.*?(\n|\r)/gm, '' )
    // 	.replace( /^\s*?(\n|\r)/gm, '' )
    // 	.trim();

    final reg = RegExp(r"^#.*?(\n|\r)", multiLine: true);
    json = json.replaceAll(reg, "");

    final reg2 = RegExp(r"^\s*?(\n|\r)", multiLine: true);
    json = json.replaceAll(reg2, "");
    json = json.trim();

    var title;
    int size = 0;
    var domainMin = Vector3(0, 0, 0);
    var domainMax = Vector3(1, 1, 1);

    final reg3 = RegExp(r"[\n\r]+");
    var lines = json.split(reg3);
    Uint8Array? data;

    var currIndex = 0;
    for (var i = 0, l = lines.length; i < l; i++) {
      var line = lines[i].trim();
      var split = line.split(RegExp(r"\s"));

      switch (split[0]) {
        case 'TITLE':
          title = line.substring(7, line.length - 1);
          break;
        case 'LUT_3D_SIZE':
          // TODO: A .CUBE LUT file specifies floating point values and could be represented with
          // more precision than can be captured with Uint8Array.
          var sizeToken = split[1];
          size = parseFloat(sizeToken).toInt();
          data = Uint8Array(size * size * size * 4);
          break;
        case 'DOMAIN_MIN':
          domainMin.x = parseFloat(split[1]);
          domainMin.y = parseFloat(split[2]);
          domainMin.z = parseFloat(split[3]);
          break;
        case 'DOMAIN_MAX':
          domainMax.x = parseFloat(split[1]);
          domainMax.y = parseFloat(split[2]);
          domainMax.z = parseFloat(split[3]);
          break;
        default:
          var r = parseFloat(split[0]);
          var g = parseFloat(split[1]);
          var b = parseFloat(split[2]);

          if (r > 1.0 || r < 0.0 || g > 1.0 || g < 0.0 || b > 1.0 || b < 0.0) {
            throw ('LUTCubeLoader : Non normalized values not supported.');
          }

          data![currIndex + 0] = (r * 255).toInt();
          data[currIndex + 1] = (g * 255).toInt();
          data[currIndex + 2] = (b * 255).toInt();
          data[currIndex + 3] = 255;
          currIndex += 4;
      }
    }

    var texture = DataTexture(null, null, null, null, null, null, null, null, null, null, null, null);
    texture.image!.data = data;
    texture.image!.width = size;
    texture.image!.height = size * size;
    texture.type = UnsignedByteType;
    texture.magFilter = LinearFilter;
    texture.wrapS = ClampToEdgeWrapping;
    texture.wrapT = ClampToEdgeWrapping;
    texture.generateMipmaps = false;

    var texture3D = Data3DTexture();
    texture3D.image!.data = data;
    texture3D.image!.width = size;
    texture3D.image!.height = size;
    texture3D.image!.depth = size;
    texture3D.type = UnsignedByteType;
    texture3D.magFilter = LinearFilter;
    texture3D.wrapS = ClampToEdgeWrapping;
    texture3D.wrapT = ClampToEdgeWrapping;
    texture3D.wrapR = ClampToEdgeWrapping;
    texture3D.generateMipmaps = false;

    return {
      "title": title,
      "size": size,
      "domainMin": domainMin,
      "domainMax": domainMax,
      "texture": texture,
      "texture3D": texture3D,
    };
  }
}
