import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ConvertNode extends Node {
  late dynamic node;
  late dynamic convertTo;

  ConvertNode(this.node, this.convertTo) : super();

  @override
  getNodeType([builder, output]) {
    return convertTo;
  }

  @override
  generate([builder, output]) {
    var convertTo = this.convertTo;

    var convertToSnippet = builder.getType(convertTo);
    var nodeSnippet = node.build(builder, convertTo);

    return "$convertToSnippet( $nodeSnippet )";
  }
}
