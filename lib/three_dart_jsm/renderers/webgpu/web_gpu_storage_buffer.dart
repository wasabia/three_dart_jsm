import 'index.dart';

class WebGPUStorageBuffer extends WebGPUBinding {
  late int usage;
  late dynamic attribute;
  late dynamic bufferGPU;

  WebGPUStorageBuffer(name, this.attribute) : super(name) {
    type = GPUBindingType.storageBuffer;

    // this.usage = GPUBufferUsage.Uniform |
    //     GPUBufferUsage.Vertex |
    //     GPUBufferUsage.Storage |
    //     GPUBufferUsage.CopyDst;

    bufferGPU = null; // set by the renderer
  }
}
