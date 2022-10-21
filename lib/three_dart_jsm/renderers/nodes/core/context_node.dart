import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ContextNode extends Node {
  late dynamic node;
  late dynamic context;

  ContextNode(this.node, [context]) : super() {
    this.context = context ?? {};
  }

  @override
  getNodeType([builder, output]) {
    return node.getNodeType(builder);
  }

  @override
  generate([builder, output]) {
    var previousContext = builder.getContext();

    Map context = {};
    context.addAll(builder.context);
    context.addAll(context);

    builder.setContext(context);

    var snippet = node.build(builder, output);

    builder.setContext(previousContext);

    return snippet;
  }
}
