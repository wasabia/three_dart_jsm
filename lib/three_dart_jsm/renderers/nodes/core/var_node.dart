import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class VarNode extends Node {
  late dynamic node;
  String? name;

  VarNode(node, [name, nodeType]) : super(nodeType) {
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
    return super.getNodeType(builder) ?? node.getNodeType(builder);
  }

  @override
  generate([builder, output]) {
    var type = builder.getVectorType(getNodeType(builder));
    var node = this.node;
    var name = this.name;

    var snippet = node.build(builder, type);

    var nodeVar = builder.getVarFromNode(this, type);

    if (name != null) {
      nodeVar.name = name;
    }

    var propertyName = builder.getPropertyName(nodeVar);

    builder.addFlowCode("$propertyName = $snippet");

    return propertyName;
  }

  @override
  getProperty(String name) {
    if (name == "xyz") {
      return xyz;
    } else if (name == "w") {
      return w;
    } else {
      return super.getProperty(name);
    }
  }
}
