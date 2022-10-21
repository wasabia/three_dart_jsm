import '../index.dart';

class WebGPUNodeSampledTexture extends WebGPUSampledTexture {
  late dynamic textureNode;

  WebGPUNodeSampledTexture(name, this.textureNode) : super(name, textureNode.value);

  @override
  getTexture() {
    return textureNode.value;
  }
}
