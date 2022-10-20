import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class VaryNode extends Node {
  late dynamic node;
  late dynamic name;

  VaryNode(this.node, [this.name]) : super() {
    generateLength = 1;
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

    var propertyName = builder.getPropertyName(nodeVary, NodeShaderStage.vertex);

    // force node run in vertex stage
    builder.flowNodeFromShaderStage(NodeShaderStage.vertex, node, type, propertyName);

    var result = builder.getPropertyName(nodeVary);

    return result;
  }
}
