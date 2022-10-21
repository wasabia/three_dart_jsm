import 'package:three_dart/three_dart.dart';

class MeshBasicNodeMaterial extends MeshBasicMaterial {
  bool isNodeMaterial = true;

  dynamic colorNode;
  dynamic opacityNode;
  dynamic alphaTestNode;
  dynamic lightNode;
  dynamic positionNode;
  dynamic emissiveNode;

  MeshBasicNodeMaterial(parameters) : super(parameters) {
    colorNode = null;
    opacityNode = null;

    alphaTestNode = null;

    lightNode = null;

    positionNode = null;
  }

  @override
  MeshBasicMaterial copy(Material source) {
    if (source is MeshBasicNodeMaterial) {
      colorNode = source.colorNode;
      opacityNode = source.opacityNode;
      alphaTestNode = source.alphaTestNode;
      lightNode = source.lightNode;
      positionNode = source.positionNode;
    }
    return super.copy(source);
  }
}
