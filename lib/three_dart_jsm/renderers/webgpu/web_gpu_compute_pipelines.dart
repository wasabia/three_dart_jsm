import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

class WebGPUComputePipelines {
  // TODO (WebGPU): implement
  // late GPUDevice device;
  late WeakMap pipelines;
  late Map stages;

  WebGPUComputePipelines(device) {
    // this.device = device;

    pipelines = WeakMap();
    stages = {"compute": WeakMap()};
  }

  get(param) {
    var pipeline = pipelines.get(param);

    // @TODO: Reuse compute pipeline if possible, introduce WebGPUComputePipeline

    if (pipeline == undefined) {
      // var device = this.device;

      // var shader = {"computeShader": param.shader};

      // programmable stage

      // var stageCompute = this.stages["compute"].get(shader);

      // if (stageCompute == undefined) {
      //   stageCompute = new WebGPUProgrammableStage(
      //       device, shader["computeShader"], 'compute');

      //   this.stages["compute"].set(shader, stageCompute);
      // }

      // pipeline = device.createComputePipeline(
      //     GPUComputePipelineDescriptor(compute: stageCompute.stage));

      pipelines.set(param, pipeline);
    }

    return pipeline;
  }

  dispose() {
    pipelines = WeakMap();
    stages = {"compute": WeakMap()};
  }
}
