import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ModelNode extends Object3DNode {
  static const String viewMatrix = 'viewMatrix';
  static const String normalMatrix = 'normalMatrix';
  static const String worldMatrix = 'worldMatrix';
  static const String position = 'position';
  static const String viewPosition = 'viewPosition';

  ModelNode([scope = ModelNode.viewMatrix]) : super(scope) {
    generateLength = 1;
  }
}
