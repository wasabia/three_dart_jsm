import 'dart:typed_data';

import 'index.dart';

class WebGPUUniformBuffer extends WebGPUBinding {
  late int bytesPerElement;
  late int usage;
  dynamic buffer;
  // GPUBuffer? bufferGPU;

  WebGPUUniformBuffer(name, [this.buffer]) : super(name) {
    bytesPerElement = Float32List.bytesPerElement;
    type = GPUBindingType.uniformBuffer;

    // this.visibility = GPUShaderStage.Vertex | GPUShaderStage.Fragment;
    // this.usage = GPUBufferUsage.Uniform | GPUBufferUsage.Storage | GPUBufferUsage.CopyDst;
    // this.bufferGPU = null; // set by the renderer
  }

  getByteLength() {
    return getFloatLength(buffer.byteLength);
  }

  getBuffer() {
    return buffer;
  }

  update() {
    return true;
  }
}
