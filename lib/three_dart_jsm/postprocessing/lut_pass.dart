import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';

import 'shader_pass.dart';

class LUTPass extends ShaderPass {
  LUTPass(Map<String, dynamic> options) : super(lutShader, null) {
    lut = options["lut"];
    intensity = options["intensity"] ?? 1;
  }

  set lut(v) {
    var material = this.material;

    if (v != lut) {
      material.uniforms["lut3d"]["value"] = null;
      material.uniforms["lut"]["value"] = null;

      if (v != null) {
        var is3dTextureDefine = v is Data3DTexture ? 1 : 0;
        if (is3dTextureDefine != material.defines!["USE_3DTEXTURE"]) {
          material.defines!["USE_3DTEXTURE"] = is3dTextureDefine;
          material.needsUpdate = true;
        }

        if (v is Data3DTexture) {
          material.uniforms["lut3d"]["value"] = v;
        } else {
          material.uniforms["lut"]["value"] = v;
          material.uniforms["lutSize"]["value"] = v.image.width;
        }
      }
    }
  }

  get lut {
    return material.uniforms["lut"]["value"] ?? material.uniforms["lut3d"]["value"];
  }

  set intensity(v) {
    material.uniforms["intensity"]["value"] = v;
  }

  get intensity {
    return material.uniforms["intensity"]["value"];
  }
}
