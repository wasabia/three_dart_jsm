import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class TempNode extends Node {
  TempNode([type]) : super(type);

  @override
  build(builder, [output]) {
    var type = builder.getVectorType(getNodeType(builder, output));

    if (builder.context["temp"] != false && type != 'void ' && output != 'void') {
      Map nodeData = builder.getDataFromNode(this);

      if (nodeData["snippet"] == null) {
        var snippet = super.build(builder, type);

        var nodeVar = builder.getVarFromNode(this, type);
        var propertyName = builder.getPropertyName(nodeVar);

        builder.addFlowCode("$propertyName = $snippet");

        nodeData["snippet"] = snippet;
        nodeData["propertyName"] = propertyName;
      }

      return builder.format(nodeData["propertyName"], type, output);
    }

    return super.build(builder, output);
  }
}
