import 'package:three_dart/three_dart.dart';

class WebGPUTextureRenderer {
  late dynamic renderer;
  late WebGLRenderTarget renderTarget;

  WebGPUTextureRenderer(this.renderer, [options]) {
    options ??= {};

    // @TODO: Consider to introduce WebGPURenderTarget or rename WebGLRenderTarget to just RenderTarget

    renderTarget = WebGLRenderTarget(1, 1, options);
  }

  getTexture() {
    return renderTarget.texture;
  }

  setSize(width, height) {
    renderTarget.setSize(width, height);
  }

  render(scene, camera) {
    var renderer = this.renderer;
    var renderTarget = this.renderTarget;

    renderer.setRenderTarget(renderTarget);
    renderer.render(scene, camera);
    renderer.setRenderTarget(null);
  }
}
