import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class VaryNode extends Node {
  late dynamic node;
  late dynamic name;

  VaryNode(node, [name]) : super() {
    generateLength = 1;
    this.node = node;
    this.name = name;
  }

  @override
  getHash([builder]) {
    return name ?? super.getHash(builder);
  }

  @override
  getNodeType([builder, output]) {
    // VaryNode is auto type

    return node.getNodeType(builder);
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);
    var node = this.node;
    var name = this.name;

    var nodeVary = builder.getVaryFromNode(this, type);

    if (name != null) {
      nodeVary.name = name;
    }

    var propertyName = builder.getPropertyName(nodeVary, NodeShaderStage.Vertex);

    // force node run in vertex stage
    builder.flowNodeFromShaderStage(NodeShaderStage.Vertex, node, type, propertyName);

    var result = builder.getPropertyName(nodeVary);

    return result;
  }
}
