import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';
import 'pass.dart';

class AfterimagePass extends Pass {
  late Map<String, dynamic> shader;
  late ShaderMaterial shaderMaterial;
  late WebGLRenderTarget textureComp;
  late WebGLRenderTarget textureOld;
  late FullScreenQuad compFsQuad;
  late FullScreenQuad copyFsQuad;

  AfterimagePass(damp, bufferSizeMap) : super() {
    shader = AfterimageShader;

    uniforms = UniformsUtils.clone(shader["uniforms"]);

    uniforms['damp']["value"] = damp ?? 0.96;

    textureComp = WebGLRenderTarget(bufferSizeMap["width"], bufferSizeMap["height"],
        WebGLRenderTargetOptions({"minFilter": LinearFilter, "magFilter": NearestFilter, "format": RGBAFormat}));

    textureOld = WebGLRenderTarget(bufferSizeMap["width"], bufferSizeMap["height"],
        WebGLRenderTargetOptions({"minFilter": LinearFilter, "magFilter": NearestFilter, "format": RGBAFormat}));

    shaderMaterial = ShaderMaterial(
        {"uniforms": uniforms, "vertexShader": shader["vertexShader"], "fragmentShader": shader["fragmentShader"]});

    compFsQuad = FullScreenQuad(shaderMaterial);

    var material = MeshBasicMaterial();
    copyFsQuad = FullScreenQuad(material);
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    uniforms['tOld']["value"] = textureOld.texture;
    uniforms['tNew']["value"] = readBuffer.texture;

    renderer.setRenderTarget(textureComp);
    compFsQuad.render(renderer);

    copyFsQuad.material.map = textureComp.texture;

    if (renderToScreen) {
      renderer.setRenderTarget(null);
      copyFsQuad.render(renderer);
    } else {
      renderer.setRenderTarget(writeBuffer);

      if (clear) renderer.clear(true, true, true);

      copyFsQuad.render(renderer);
    }

    // Swap buffers.
    var temp = textureOld;
    textureOld = textureComp;
    textureComp = temp;
    // Now textureOld contains the latest image, ready for the next frame.
  }

  @override
  setSize(width, height) {
    textureComp.setSize(width, height);
    textureOld.setSize(width, height);
  }
}
