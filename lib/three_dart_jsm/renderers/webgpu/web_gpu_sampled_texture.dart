import 'index.dart';

class WebGPUSampledTexture extends WebGPUBinding {
  late dynamic texture;
  late dynamic textureGPU;
  late String dimension;

  bool isSampledTexture = true;

  WebGPUSampledTexture(name, this.texture) : super(name) {
    dimension = GPUTextureViewDimension.twoD;
    type = GPUBindingType.sampledTexture;
    // this.visibility = GPUShaderStage.Fragment;

    textureGPU = null; // set by the renderer
  }

  getTexture() {
    return texture;
  }
}

class WebGPUSampledArrayTexture extends WebGPUSampledTexture {
  WebGPUSampledArrayTexture(name, texture) : super(name, texture) {
    dimension = GPUTextureViewDimension.twoDArray;
  }
}

class WebGPUSampled3DTexture extends WebGPUSampledTexture {
  WebGPUSampled3DTexture(name, texture) : super(name, texture) {
    dimension = GPUTextureViewDimension.threeD;
  }
}

class WebGPUSampledCubeTexture extends WebGPUSampledTexture {
  WebGPUSampledCubeTexture(name, texture) : super(name, texture) {
    dimension = GPUTextureViewDimension.cube;
  }
}
