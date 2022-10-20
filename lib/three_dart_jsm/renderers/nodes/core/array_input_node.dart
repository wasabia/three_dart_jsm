import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ArrayInputNode extends InputNode {
  late List nodes;

  ArrayInputNode([nodes]) : super() {
    this.nodes = nodes ?? [];
  }

  @override
  getNodeType([builder, output]) {
    return nodes[0].getNodeType(builder);
  }
}
