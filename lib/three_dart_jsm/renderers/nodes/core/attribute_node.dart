import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class AttributeNode extends Node {
  late String _attributeName;

  AttributeNode(attributeName, nodeType) : super(nodeType) {
    generateLength = 1;
    _attributeName = attributeName;
  }

  @override
  getHash([builder]) {
    return getAttributeName(builder);
  }

  setAttributeName(attributeName) {
    _attributeName = attributeName;

    return this;
  }

  getAttributeName(builder) {
    return _attributeName;
  }

  @override
  generate([builder, output]) {
    var attribute = builder.getAttribute(getAttributeName(builder), getNodeType(builder));

    if (builder.isShaderStage('vertex')) {
      return attribute.name;
    } else {
      var nodeVary = VaryNode(this);

      return nodeVary.build(builder, attribute.type);
    }
  }
}
