import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class CondNode extends Node {
  late dynamic node;
  late dynamic ifNode;
  late dynamic elseNode;

  CondNode(this.node, [this.ifNode, this.elseNode]) : super();

  @override
  getNodeType([builder, output]) {
    var ifType = ifNode.getNodeType(builder);
    var elseType = elseNode.getNodeType(builder);

    if (builder.getTypeLength(elseType) > builder.getTypeLength(ifType)) {
      return elseType;
    }

    return ifType;
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);

    var context = {"temp": false};
    var nodeProperty = PropertyNode(null, type).build(builder);

    var nodeSnippet = ContextNode(node /*, context*/).build(builder, 'bool'),
        ifSnippet = ContextNode(ifNode, context).build(builder, type),
        elseSnippet = ContextNode(elseNode, context).build(builder, type);

    builder.addFlowCode("""if ( $nodeSnippet ) {

\t\t$nodeProperty = $ifSnippet;

\t} else {

\t\t$nodeProperty = $elseSnippet;

\t}""");

    return nodeProperty;
  }
}
