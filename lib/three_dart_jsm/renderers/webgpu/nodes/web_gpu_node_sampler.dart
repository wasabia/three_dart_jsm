import '../index.dart';

class WebGPUNodeSampler extends WebGPUSampler {
  late dynamic textureNode;

  WebGPUNodeSampler(name, this.textureNode) : super(name, textureNode.value);

  @override
  getTexture() {
    return textureNode.value;
  }
}
