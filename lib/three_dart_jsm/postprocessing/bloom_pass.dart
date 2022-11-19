import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';
import 'pass.dart';

class BloomPass extends Pass {
  late WebGLRenderTarget renderTargetX;
  late WebGLRenderTarget renderTargetY;
  late ShaderMaterial materialCopy;
  late Map<String, dynamic> convolutionUniforms;
  late ShaderMaterial materialConvolution;

  BloomPass(num? strength, num? kernelSize, sigma, resolution) : super() {
    strength = (strength != null) ? strength : 1;
    kernelSize = (kernelSize != null) ? kernelSize : 25;
    sigma = (sigma != null) ? sigma : 4.0;
    resolution = (resolution != null) ? resolution : 256;

    // render targets

    var pars = {"minFilter": LinearFilter, "magFilter": LinearFilter, "format": RGBAFormat};

    renderTargetX = WebGLRenderTarget(resolution, resolution, WebGLRenderTargetOptions(pars));
    renderTargetX.texture.name = 'BloomPass.x';
    renderTargetY = WebGLRenderTarget(resolution, resolution, WebGLRenderTargetOptions(pars));
    renderTargetY.texture.name = 'BloomPass.y';

    // copy material
    uniforms = UniformsUtils.clone(copyShader["uniforms"]);

    uniforms['opacity']["value"] = strength;

    materialCopy = ShaderMaterial({
      "uniforms": uniforms,
      "vertexShader": copyShader["vertexShader"],
      "fragmentShader": copyShader["fragmentShader"],
      "blending": AdditiveBlending,
      "transparent": true
    });

    // convolution material
    convolutionUniforms = UniformsUtils.clone(convolutionShader["uniforms"]);

    convolutionUniforms['uImageIncrement']["value"] = BloomPass.blurX;
    convolutionUniforms['cKernel']["value"] = convolutionShaderBuildKernel(sigma);

    materialConvolution = ShaderMaterial({
      "uniforms": convolutionUniforms,
      "vertexShader": convolutionShader["vertexShader"],
      "fragmentShader": convolutionShader["fragmentShader"],
      "defines": {'KERNEL_SIZE_FLOAT': toFixed(kernelSize, 1), 'KERNEL_SIZE_INT': toFixed(kernelSize, 0)}
    });

    needsSwap = false;

    fsQuad = FullScreenQuad(null);
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    if (maskActive == true) renderer.state.buffers.stencil.setTest(false);

    // Render quad with blured scene into texture (convolution pass 1)

    fsQuad.material = materialConvolution;

    convolutionUniforms['tDiffuse']["value"] = readBuffer.texture;
    convolutionUniforms['uImageIncrement']["value"] = BloomPass.blurX;

    renderer.setRenderTarget(renderTargetX);
    renderer.clear(null, null, null);
    fsQuad.render(renderer);

    // Render quad with blured scene into texture (convolution pass 2)

    convolutionUniforms['tDiffuse']["value"] = renderTargetX.texture;
    convolutionUniforms['uImageIncrement']["value"] = BloomPass.blurY;

    renderer.setRenderTarget(renderTargetY);
    renderer.clear(null, null, null);
    fsQuad.render(renderer);

    // Render original scene with superimposed blur to texture

    fsQuad.material = materialCopy;

    uniforms['tDiffuse']["value"] = renderTargetY.texture;

    if (maskActive == true) renderer.state.buffers.stencil.setTest(true);

    renderer.setRenderTarget(readBuffer);
    if (clear) renderer.clear(null, null, null);
    fsQuad.render(renderer);
  }

  static Vector2 blurX = Vector2(0.001953125, 0.0);
  static Vector2 blurY = Vector2(0.0, 0.001953125);
}
