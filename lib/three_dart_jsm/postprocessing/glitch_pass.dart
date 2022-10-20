import 'dart:typed_data';

import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';

import 'pass.dart';

class GlitchPass extends Pass {
  bool goWild = false;
  num curF = 0;
  late num randX;

  GlitchPass(dt_size) : super() {
    if (DigitalGlitch == null) {
      print('THREE.GlitchPass relies on DigitalGlitch');
    }

    var shader = DigitalGlitch;
    uniforms = UniformsUtils.clone(shader["uniforms"]);

    dt_size ??= 64;

    uniforms['tDisp']["value"] = generateHeightmap(dt_size);

    material = ShaderMaterial(
        {"uniforms": uniforms, "vertexShader": shader["vertexShader"], "fragmentShader": shader["fragmentShader"]});

    fsQuad = FullScreenQuad(material);
    generateTrigger();
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    uniforms['tDiffuse']["value"] = readBuffer.texture;
    uniforms['seed']["value"] = Math.random(); //default seeding
    uniforms['byp']["value"] = 0;

    if (curF % randX == 0 || goWild == true) {
      uniforms['amount']["value"] = Math.random() / 30;
      uniforms['angle']["value"] = MathUtils.randFloat(-Math.pi, Math.pi);
      uniforms['seed_x']["value"] = MathUtils.randFloat(-1, 1);
      uniforms['seed_y']["value"] = MathUtils.randFloat(-1, 1);
      uniforms['distortion_x']["value"] = MathUtils.randFloat(0, 1);
      uniforms['distortion_y']["value"] = MathUtils.randFloat(0, 1);
      curF = 0;
      generateTrigger();
    } else if (curF % randX < randX / 5) {
      uniforms['amount']["value"] = Math.random() / 90;
      uniforms['angle']["value"] = MathUtils.randFloat(-Math.pi, Math.pi);
      uniforms['distortion_x']["value"] = MathUtils.randFloat(0, 1);
      uniforms['distortion_y']["value"] = MathUtils.randFloat(0, 1);
      uniforms['seed_x']["value"] = MathUtils.randFloat(-0.3, 0.3);
      uniforms['seed_y']["value"] = MathUtils.randFloat(-0.3, 0.3);
    } else if (goWild == false) {
      uniforms['byp']["value"] = 1;
    }

    curF++;

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      fsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);
      if (clear) renderer.clear();
      fsQuad.render(renderer);
    }
  }

  generateTrigger() {
    randX = MathUtils.randInt(120, 240);
  }

  generateHeightmap(dtSize) {
    var dataArr = Float32List(dtSize * dtSize * 3);
    var length = dtSize * dtSize;

    for (var i = 0; i < length; i++) {
      var val = MathUtils.randFloat(0, 1);
      dataArr[i * 3 + 0] = val;
      dataArr[i * 3 + 1] = val;
      dataArr[i * 3 + 2] = val;
    }

    return DataTexture(dataArr, dtSize, dtSize, RGBFormat, FloatType, null, null, null, null, null, null, null);
  }
}
