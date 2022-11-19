import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';

import 'pass.dart';

class FilmPass extends Pass {
  FilmPass(
    noiseIntensity,
    scanlinesIntensity,
    scanlinesCount,
    grayscale,
  ) : super() {
    var shader = filmShader;

    uniforms = UniformsUtils.clone(Map<String, dynamic>.from(shader["uniforms"]));

    material = ShaderMaterial({
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"],
    });

    if (grayscale != null) uniforms["grayscale"]["value"] = grayscale;
    if (noiseIntensity != null) {
      uniforms["nIntensity"]["value"] = noiseIntensity;
    }
    if (scanlinesIntensity != null) {
      uniforms["sIntensity"]["value"] = scanlinesIntensity;
    }
    if (scanlinesCount != null) {
      uniforms["sCount"]["value"] = scanlinesCount;
    }

    fsQuad = FullScreenQuad(material);
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    uniforms['tDiffuse']["value"] = readBuffer.texture;
    uniforms['time']["value"] += deltaTime;

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
