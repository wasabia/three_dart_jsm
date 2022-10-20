import 'index.dart';

class WebGPUSampler extends WebGPUBinding {
  bool isSampler = true;

  late dynamic texture;
  late dynamic samplerGPU;

  WebGPUSampler(name, this.texture) : super(name) {
    type = GPUBindingType.sampler;
    samplerGPU = null;
  }

  getTexture() {
    return texture;
  }
}
