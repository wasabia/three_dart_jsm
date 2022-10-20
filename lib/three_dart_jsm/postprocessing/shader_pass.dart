import 'package:three_dart/three_dart.dart';

import 'pass.dart';

class ShaderPass extends Pass {
  late dynamic textureID;

  ShaderPass(shader, textureID) : super() {
    this.textureID = (textureID != null) ? textureID : 'tDiffuse';

    if (shader.runtimeType.toString() == "ShaderMaterial") {
      uniforms = shader.uniforms;

      material = shader;
    } else if (shader != null) {
      uniforms = UniformsUtils.clone(shader["uniforms"]);

      Map<String, dynamic> defines = {};
      defines.addAll(shader["defines"] ?? {});
      material = ShaderMaterial({
        "defines": defines,
        "uniforms": uniforms,
        "vertexShader": shader["vertexShader"],
        "fragmentShader": shader["fragmentShader"]
      });
    }

    fsQuad = FullScreenQuad(material);
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    if (uniforms[textureID] != null) {
      uniforms[textureID]["value"] = readBuffer.texture;
    }

    fsQuad.material = material;

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
      if (clear) {
        renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
      }
      fsQuad.render(renderer);
    }
  }
}
