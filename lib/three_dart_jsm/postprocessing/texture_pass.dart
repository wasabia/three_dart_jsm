import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';

import 'pass.dart';

class TexturePass extends Pass {
  late Texture map;
  late num opacity;

  TexturePass(this.map, opacity) : super() {
    var shader = copyShader;

    this.opacity = (opacity != null) ? opacity : 1.0;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    material = ShaderMaterial({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"],
      "depthTest": false,
      "depthWrite": false
    });

    needsSwap = false;

    fsQuad = FullScreenQuad(null);
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    var oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    fsQuad.material = material;

    uniforms['opacity']["value"] = opacity;
    uniforms['tDiffuse']["value"] = map;
    material.transparent = (opacity < 1.0);

    renderer.setRenderTarget(renderToScreen ? null : readBuffer);
    if (clear) renderer.clear(true, true, true);
    fsQuad.render(renderer);

    renderer.autoClear = oldAutoClear;
  }
}
