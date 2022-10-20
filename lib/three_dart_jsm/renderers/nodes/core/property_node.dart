import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class PropertyNode extends Node {
  String? name;

  PropertyNode([this.name, nodeType = 'vec4']) : super(nodeType);

  @override
  getHash([builder]) {
    return name ?? super.getHash(builder);
  }

  @override
  generate([builder, output]) {
    var nodeVary = builder.getVarFromNode(this, getNodeType(builder));
    var name = this.name;

    if (name != null) {
      nodeVary.name = name;
    }

    return builder.getPropertyName(nodeVary);
  }
}
