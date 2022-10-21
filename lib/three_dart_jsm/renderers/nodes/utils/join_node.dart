import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class JoinNode extends Node {
  late List nodes;

  JoinNode([nodes]) : super() {
    generateLength = 1;

    this.nodes = nodes ?? [];
  }

  @override
  getNodeType([builder, output]) {
    return builder.getTypeFromLength(nodes.length);
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);
    var nodes = this.nodes;

    var snippetValues = [];

    for (var i = 0; i < nodes.length; i++) {
      var input = nodes[i];

      var inputSnippet = input.build(builder, 'float');

      snippetValues.add(inputSnippet);
    }

    return "${builder.getType(type)}( ${snippetValues.join(', ')} )";
  }
}
