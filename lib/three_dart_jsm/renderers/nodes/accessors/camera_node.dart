import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class CameraNode extends Object3DNode {
  static const String projectionMatrix = 'projectionMatrix';
  static const String viewMatrix = 'viewMatrix';
  static const String normalMatrix = 'normalMatrix';
  static const String worldMatrix = 'worldMatrix';
  static const String position = 'position';
  static const String viewPosition = 'viewPosition';

  late dynamic _inputNode;

  CameraNode([scope = CameraNode.position]) : super(scope) {
    generateLength = 1;
    _inputNode = null;
  }

  @override
  getNodeType([builder, output]) {
    var scope = this.scope;

    if (scope == CameraNode.projectionMatrix) {
      return 'mat4';
    }

    return super.getNodeType(builder);
  }

  @override
  update([frame]) {
    var camera = frame.camera;
    var inputNode = _inputNode;
    var scope = this.scope;

    if (scope == CameraNode.projectionMatrix) {
      inputNode.value = camera.projectionMatrix;
    } else if (scope == CameraNode.viewMatrix) {
      inputNode.value = camera.matrixWorldInverse;
    } else {
      super.update(frame);
    }
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    if (scope == CameraNode.projectionMatrix) {
      _inputNode = Matrix4Node(null);
    }

    return super.generate(builder);
  }
}
