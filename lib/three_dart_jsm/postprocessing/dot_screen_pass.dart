import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';
import 'pass.dart';

class DotScreenPass extends Pass {
  DotScreenPass(Vector2? center, num? angle, num? scale) : super() {
    var shader = dotScreenShader;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    if (center != null) uniforms['center']["value"].copy(center);
    if (angle != null) uniforms['angle']["value"] = angle;
    if (scale != null) uniforms['scale']["value"] = scale;

    material = ShaderMaterial({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"],
    });

    fsQuad = FullScreenQuad(material);
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    uniforms['tDiffuse']["value"] = readBuffer.texture;
    uniforms['tSize']["value"].set(readBuffer.width, readBuffer.height);

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      if (clear) renderer.clear();
      fsQuad.render(renderer);
    }
  }
}
