import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ReferenceNode extends Node {
  late dynamic property;
  late dynamic object;
  late dynamic node;

  ReferenceNode(this.property, inputType, [this.object]) : super() {
    this.inputType = inputType;

    node = null;

    updateType = NodeUpdateType.object;

    setNodeType(inputType);
  }

  setNodeType(inputType) {
    var node;
    var nodeType = inputType;

    if (nodeType == 'float') {
      node = FloatNode();
    } else if (nodeType == 'vec2') {
      node = Vector2Node(null);
    } else if (nodeType == 'vec3') {
      node = Vector3Node(null);
    } else if (nodeType == 'vec4') {
      node = Vector4Node(null);
    } else if (nodeType == 'color') {
      node = ColorNode(null);
      nodeType = 'vec3';
    } else if (nodeType == 'texture') {
      node = TextureNode();
      nodeType = 'vec4';
    }

    this.node = node;
    this.nodeType = nodeType;
    this.inputType = inputType;
  }

  @override
  getNodeType([builder, output]) {
    return inputType;
  }

  @override
  update([frame]) {
    var object = this.object ?? frame.object;
    var value = object.getProperty(property);

    node.value = value;
  }

  @override
  generate([builder, output]) {
    return node.build(builder, getNodeType(builder));
  }
}
