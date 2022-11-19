import 'package:flutter_gl/native-array/index.dart';
import 'package:three_dart/extra/console.dart';

import 'index.dart';

class WebGPUUniformsGroup extends WebGPUUniformBuffer {
  late List uniforms;

  WebGPUUniformsGroup(name) : super(name) {
    // the order of uniforms in this array must match the order of uniforms in the shader

    uniforms = [];
  }

  addUniform(uniform) {
    uniforms.add(uniform);

    return this;
  }

  removeUniform(uniform) {
    var index = uniforms.indexOf(uniform);

    if (index != -1) {
      uniforms.removeAt(index);
    }

    return this;
  }

  @override
  getBuffer() {
    var buffer = this.buffer;

    if (buffer == null) {
      var byteLength = getByteLength();

      buffer = Float32Array(byteLength ~/ 4);

      this.buffer = buffer;
    }

    return buffer;
  }

  @override
  getByteLength() {
    int offset = 0; // global buffer offset in bytes

    for (var i = 0, l = uniforms.length; i < l; i++) {
      var uniform = uniforms[i];

      // offset within a single chunk in bytes

      var chunkOffset = offset % gpuChunkSize;
      var remainingSizeInChunk = gpuChunkSize - chunkOffset;

      // conformance tests

      if (chunkOffset != 0 && (remainingSizeInChunk - uniform.boundary) < 0) {
        // check for chunk overflow

        offset += (gpuChunkSize - chunkOffset);
      } else if (chunkOffset % uniform.boundary != 0) {
        // check for correct alignment

        offset += (chunkOffset % uniform.boundary).toInt();
      }

      uniform.offset = (offset ~/ bytesPerElement);

      int v = (uniform.itemSize * bytesPerElement).toInt();
      offset += v;
    }

    return offset;
  }

  @override
  update() {
    var updated = false;

    for (var uniform in uniforms) {
      if (updateByType(uniform) == true) {
        updated = true;
      }
    }

    return updated;
  }

  updateByType(uniform) {
    if (uniform is FloatUniform) return updateNumber(uniform);
    if (uniform is Vector2Uniform) return updateVector2(uniform);
    if (uniform is Vector3Uniform) return updateVector3(uniform);
    if (uniform is Vector4Uniform) return updateVector4(uniform);
    if (uniform is ColorUniform) return updateColor(uniform);
    if (uniform is Matrix3Uniform) return updateMatrix3(uniform);
    if (uniform is Matrix4Uniform) return updateMatrix4(uniform);

    console.error('THREE.WebGPUUniformsGroup: Unsupported uniform type.', uniform);
  }

  updateNumber(uniform) {
    var updated = false;

    var a = buffer;
    var v = uniform.getValue();
    var offset = uniform.offset;

    if (a[offset] != v) {
      a[offset] = v.toDouble();
      updated = true;
    }

    return updated;
  }

  updateVector2(uniform) {
    var updated = false;

    var a = buffer;
    var v = uniform.getValue();
    var offset = uniform.offset;

    if (a[offset + 0] != v.x || a[offset + 1] != v.y) {
      a[offset + 0] = v.x;
      a[offset + 1] = v.y;

      updated = true;
    }

    return updated;
  }

  updateVector3(uniform) {
    var updated = false;

    var a = buffer;
    var v = uniform.getValue();
    var offset = uniform.offset;

    if (a[offset + 0] != v.x || a[offset + 1] != v.y || a[offset + 2] != v.z) {
      a[offset + 0] = v.x;
      a[offset + 1] = v.y;
      a[offset + 2] = v.z;

      updated = true;
    }

    return updated;
  }

  updateVector4(uniform) {
    var updated = false;

    var a = buffer;
    var v = uniform.getValue();
    var offset = uniform.offset;

    if (a[offset + 0] != v.x || a[offset + 1] != v.y || a[offset + 2] != v.z || a[offset + 4] != v.w) {
      a[offset + 0] = v.x;
      a[offset + 1] = v.y;
      a[offset + 2] = v.z;
      a[offset + 3] = v.w;

      updated = true;
    }

    return updated;
  }

  updateColor(uniform) {
    var updated = false;

    var a = buffer;
    var c = uniform.getValue();
    var offset = uniform.offset;

    if (a[offset + 0] != c.r || a[offset + 1] != c.g || a[offset + 2] != c.b) {
      a[offset + 0] = c.r;
      a[offset + 1] = c.g;
      a[offset + 2] = c.b;

      updated = true;
    }

    return updated;
  }

  updateMatrix3(uniform) {
    var updated = false;

    var a = buffer;
    var e = uniform.getValue().elements;
    var offset = uniform.offset;

    if (a[offset + 0] != e[0] ||
        a[offset + 1] != e[1] ||
        a[offset + 2] != e[2] ||
        a[offset + 4] != e[3] ||
        a[offset + 5] != e[4] ||
        a[offset + 6] != e[5] ||
        a[offset + 8] != e[6] ||
        a[offset + 9] != e[7] ||
        a[offset + 10] != e[8]) {
      a[offset + 0] = e[0];
      a[offset + 1] = e[1];
      a[offset + 2] = e[2];
      a[offset + 4] = e[3];
      a[offset + 5] = e[4];
      a[offset + 6] = e[5];
      a[offset + 8] = e[6];
      a[offset + 9] = e[7];
      a[offset + 10] = e[8];

      updated = true;
    }

    return updated;
  }

  updateMatrix4(Matrix4Uniform uniform) {
    var updated = false;

    var a = buffer;
    var e = uniform.getValue().elements;
    var offset = uniform.offset;

    if (arraysEqual(a, e, offset) == false) {
      if (e is NativeArray) {
        a.set(e.toDartList(), offset);
      } else {
        a.set(e, offset);
      }

      updated = true;
    }

    return updated;
  }
}

arraysEqual(a, b, offset) {
  for (var i = 0, l = b.length; i < l; i++) {
    if (a[offset + i] != b[i]) return false;
  }

  return true;
}
