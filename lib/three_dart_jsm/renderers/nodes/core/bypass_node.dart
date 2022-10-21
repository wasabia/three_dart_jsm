import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class BypassNode extends Node {
  late dynamic outputNode;
  late dynamic callNode;

  BypassNode(returnNode, this.callNode) : super() {
    outputNode = returnNode;
  }

  @override
  getNodeType([builder, output]) {
    return outputNode.getNodeType(builder);
  }

  @override
  generate([builder, output]) {
    var snippet = callNode.build(builder, 'void');

    if (snippet != '') {
      builder.addFlowCode(snippet);
    }

    return outputNode.build(builder, output);
  }
}
