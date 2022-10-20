import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class SplitNode extends Node {
  late dynamic node;
  late String components;

  SplitNode(this.node, [this.components = 'x']) : super() {
    generateLength = 1;
  }

  getVectorLength() {
    var vectorLength = components.length;

    for (var c in components.split('')) {
      vectorLength = Math.max(vector.indexOf(c) + 1, vectorLength);
    }

    return vectorLength;
  }

  @override
  getNodeType([builder, output]) {
    return builder.getTypeFromLength(components.length);
  }

  @override
  generate([builder, output]) {
    var node = this.node;
    var nodeTypeLength = builder.getTypeLength(node.getNodeType(builder));

    if (nodeTypeLength > 1) {
      var type;

      var componentsLength = getVectorLength();

      if (componentsLength >= nodeTypeLength) {
        // need expand the input node

        type = builder.getTypeFromLength(getVectorLength());
      }

      var nodeSnippet = node.build(builder, type);

      return "$nodeSnippet.$components";
    } else {
      // ignore components if node is a float

      return node.build(builder);
    }
  }
}
