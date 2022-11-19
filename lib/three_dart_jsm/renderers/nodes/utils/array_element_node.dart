import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ArrayElementNode extends Node {
  late dynamic node;
  late dynamic indexNode;

  ArrayElementNode(this.node, this.indexNode) : super();

  @override
  getNodeType([builder, output]) {
    return node.getNodeType(builder);
  }

  @override
  generate([builder, output]) {
    var nodeSnippet = node.build(builder);
    var indexSnippet = indexNode.build(builder, 'int');

    return "$nodeSnippet[ $indexSnippet ]";
  }
}
