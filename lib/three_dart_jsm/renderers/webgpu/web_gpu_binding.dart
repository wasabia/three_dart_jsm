class WebGPUBinding {
  late String name;
  late dynamic visibility;
  late dynamic type;
  late bool isShared;

  WebGPUBinding([this.name = '']) {
    visibility = null;
    type = null; // read-only
    isShared = false;
  }

  setVisibility(visibility) {
    this.visibility = visibility;
  }
}
