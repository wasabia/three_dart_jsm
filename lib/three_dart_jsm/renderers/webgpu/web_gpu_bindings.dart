import 'package:flutter_gl/native-array/index.dart';
import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

import 'index.dart';

class WebGPUBindings {
  // TODO (WebGPU): implement
  // late GPUDevice device;
  late WebGPUInfo info;
  late WebGPUProperties properties;
  late WebGPUTextures textures;
  late WebGPURenderPipelines renderPipelines;
  late WebGPUComputePipelines computePipelines;
  late WebGPUAttributes attributes;
  late WebGPUNodes nodes;
  late WeakMap uniformsData;
  late WeakMap updateMap;

  WebGPUBindings(
    device,
    this.info,
    this.properties,
    this.textures,
    this.renderPipelines,
    this.computePipelines,
    this.attributes,
    this.nodes,
  ) {
    // this.device = device;
    uniformsData = WeakMap();
    updateMap = WeakMap();
  }

  Map get(object) {
    var data = uniformsData.get(object);

    if (data == undefined) {
      // each object defines an array of bindings (ubos, textures, samplers etc.)

      // var nodeBuilder = this.nodes.get(object);
      // var bindings = nodeBuilder.getBindings();

      // setup (static) binding layout and (dynamic) binding group

      // WebGPURenderPipeline renderPipeline = this.renderPipelines.get(object);

      // var bindGroupLayout = renderPipeline.pipeline.getBindGroupLayout( 0 );
      // var bindGroupLayout = renderPipeline.bindGroupLayout;

      // var bindGroup = this._createBindGroup(bindings, bindGroupLayout);

      // data = {"layout": bindGroupLayout, "group": bindGroup, "bindings": bindings};

      uniformsData.set(object, data);
    }

    return data;
  }

  remove(object) {
    uniformsData.delete(object);
  }

  getForCompute(param) {
    var data = uniformsData.get(param);

    if (data == undefined) {
      // bindings are not yet retrieved via node material

      var bindings = param.bindings != undefined ? param.bindings.slice() : [];

      var computePipeline = computePipelines.get(param);

      var bindLayout = computePipeline.getBindGroupLayout(0);
      var bindGroup = _createBindGroup(bindings, bindLayout);

      data = {"layout": bindLayout, "group": bindGroup, "bindings": bindings};

      uniformsData.set(param, data);
    }

    return data;
  }

  update(object) {
    var textures = this.textures;

    var data = get(object);

    var bindings = data["bindings"];

    var updateMap = this.updateMap;
    var frame = info.render["frame"];

    var needsBindGroupRefresh = false;

    // iterate over all bindings and check if buffer updates or a new binding group is required

    for (var binding in bindings) {
      var isShared = binding.isShared;
      var isUpdated = updateMap.get(binding) == frame;

      if (isShared && isUpdated) continue;
      if (binding is WebGPUUniformBuffer) {
        var buffer = binding.getBuffer();
        // var bufferGPU = binding.bufferGPU!;

        var needsBufferWrite = binding.update();

        if (needsBufferWrite == true) {
          if (buffer is Float32Array) {
            // this.device.queue.writeBuffer(bufferGPU, 0, buffer.toDartList(), buffer.lengthInBytes);
          } else {
            // this.device.queue.writeBuffer(bufferGPU, 0, buffer, buffer.lengthInBytes);
          }
        }
      } else if (binding.isStorageBuffer) {
        var attribute = binding.attribute;
        attributes.update(attribute, false, binding.usage);
      } else if (binding.isSampler) {
        var texture = binding.getTexture();

        textures.updateSampler(texture);

        var samplerGPU = textures.getSampler(texture);

        if (binding.samplerGPU != samplerGPU) {
          binding.samplerGPU = samplerGPU;
          needsBindGroupRefresh = true;
        }
      } else if (binding.isSampledTexture) {
        var texture = binding.getTexture();

        var needsTextureRefresh = textures.updateTexture(texture);
        var textureGPU = textures.getTextureGPU(texture);

        if (textureGPU != undefined && binding.textureGPU != textureGPU || needsTextureRefresh == true) {
          binding.textureGPU = textureGPU;
          needsBindGroupRefresh = true;
        }
      }

      updateMap.set(binding, frame);
    }

    if (needsBindGroupRefresh == true) {
      data["group"] = _createBindGroup(bindings, data["layout"]);
    }
  }

  dispose() {
    uniformsData = WeakMap();
    updateMap = WeakMap();
  }

  _createBindGroup(bindings, layout) {
    // var bindingPoint = 0;
    // List<GPUBindGroupEntry> entries = [];

    // for (var binding in bindings) {
    //   if (binding is WebGPUUniformBuffer) {
    //     if (binding.bufferGPU == null) {
    //       var byteLength = binding.getByteLength();
    //       binding.bufferGPU = this.device.createBuffer(GPUBufferDescriptor(size: byteLength, usage: binding.usage));
    //     }

    //     entries.add(GPUBindGroupEntry(binding: bindingPoint, buffer: binding.bufferGPU));
    //   } else if (binding is WebGPUStorageBuffer) {
    //     if (binding.bufferGPU == null) {
    //       var attribute = binding.attribute;

    //       this.attributes.update(attribute, false, binding.usage);
    //       binding.bufferGPU = this.attributes.get(attribute).buffer;
    //     }

    //     entries.add(GPUBindGroupEntry(binding: bindingPoint, buffer: binding.bufferGPU));
    //   } else if (binding is WebGPUSampler) {
    //     if (binding.samplerGPU == null) {
    //       binding.samplerGPU = this.textures.getDefaultSampler();
    //     }

    //     entries.add(GPUBindGroupEntry(binding: bindingPoint, sampler: binding.samplerGPU));
    //   } else if (binding is WebGPUSampledTexture) {
    //     if (binding.textureGPU == null) {
    //       if (binding is WebGPUSampledCubeTexture) {
    //         binding.textureGPU = this.textures.getDefaultCubeTexture();
    //       } else {
    //         binding.textureGPU = this.textures.getDefaultTexture();
    //       }
    //     }

    //     convertDimension(String dim) {
    //       if (dim == "2d") {
    //         return 1;
    //       } else {
    //         throw ("WebGPUBindings convertDimension dim: $dim need support ");
    //       }
    //     }

    //     int _dim = convertDimension(binding.dimension);

    //     entries.add(GPUBindGroupEntry(
    //         binding: bindingPoint,
    //         textureView: binding.textureGPU.createView(GPUTextureViewDescriptor(dimension: _dim))));
    //   }

    //   bindingPoint++;
    // }

    // var _bindGroup = this
    //     .device
    //     .createBindGroup(GPUBindGroupDescriptor(layout: layout, entries: entries, entryCount: entries.length));

    // return _bindGroup;
  }
}
