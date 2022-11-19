int _id = 0;

class WebGPUProgrammableStage {
  late int id;
  late dynamic code;
  late dynamic type;
  late int usedTimes;

  late Map stage;
// TODO (WebGPU): implement
  WebGPUProgrammableStage(device, this.code, this.type) {
    id = _id++;
    usedTimes = 0;

    // print("WebGPUProgrammableStage type: ${type} ${type.runtimeType} ===============================");
    // print(code);

    // var module =
    // device.createShaderModule(GPUShaderModuleDescriptor(code: code));
    // this.stage = {"module": module, "entryPoint": 'main'};
  }
}
