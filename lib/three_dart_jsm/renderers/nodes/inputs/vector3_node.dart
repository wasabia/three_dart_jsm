import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Vector3Node extends InputNode {
  Vector3Node([value]) : super('vec3') {
    this.value = value ?? Vector3();
  }
}
