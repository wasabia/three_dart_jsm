import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class FloatNode extends InputNode {
  FloatNode([value = 0]) : super('float') {
    generateLength = 2;

    this.value = value;
  }
}
