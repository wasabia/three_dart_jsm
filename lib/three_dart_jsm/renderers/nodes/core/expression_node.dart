import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ExpressionNode extends TempNode {
  late String snipped;

  String? name;

  ExpressionNode([this.snipped = '', nodeType = 'void']) : super(nodeType) {
    generateLength = 1;
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);
    var snipped = this.snipped;

    if (type == 'void') {
      builder.addFlowCode(snipped);
    } else {
      return "( $snipped )";
    }
  }
}
