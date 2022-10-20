import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Matrix3Node extends InputNode {
  Matrix3Node([value]) : super('mat3') {
    this.value = value ?? Matrix3();
  }
}
