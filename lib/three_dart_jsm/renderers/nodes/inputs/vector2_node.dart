import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Vector2Node extends InputNode {
  Vector2Node([value]) : super('vec2') {
    this.value = value ?? Vector2();
  }
}
