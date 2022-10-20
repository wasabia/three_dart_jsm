import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Vector4Node extends InputNode {
  Vector4Node([value]) : super('vec4') {
    this.value = value ?? Vector4();
  }
}
