import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Object3DNode extends Node {
  static const String viewMatric = 'viewMatrix';
  static const String normalMatrix = 'normalMatrix';
  static const String worldMatrix = 'worldMatrix';
  static const String position = 'position';
  static const String viewPosition = 'viewPosition';

  late String scope;
  late dynamic object3d;
  late dynamic _inputNode;

  Object3DNode([this.scope = Object3DNode.viewMatric, this.object3d]) : super() {
    updateType = NodeUpdateType.object;
    _inputNode = null;
  }

  @override
  getNodeType([builder, output]) {
    var scope = this.scope;

    if (scope == Object3DNode.worldMatrix || scope == Object3DNode.viewMatric) {
      return 'mat4';
    } else if (scope == Object3DNode.normalMatrix) {
      return 'mat3';
    } else if (scope == Object3DNode.position || scope == Object3DNode.viewPosition) {
      return 'vec3';
    }
  }

  @override
  update([frame]) {
    var object = object3d ?? frame.object;
    var inputNode = _inputNode;
    var camera = frame.camera;
    var scope = this.scope;

    if (scope == Object3DNode.viewMatric) {
      inputNode.value = object.modelViewMatrix;
    } else if (scope == Object3DNode.normalMatrix) {
      inputNode.value = object.normalMatrix;
    } else if (scope == Object3DNode.worldMatrix) {
      inputNode.value = object.matrixWorld;
    } else if (scope == Object3DNode.position) {
      inputNode.value.setFromMatrixPosition(object.matrixWorld);
    } else if (scope == Object3DNode.viewPosition) {
      inputNode.value.setFromMatrixPosition(object.matrixWorld);

      inputNode.value.applyMatrix4(camera.matrixWorldInverse);
    }
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    if (scope == Object3DNode.worldMatrix || scope == Object3DNode.viewMatric) {
      _inputNode = Matrix4Node();
    } else if (scope == Object3DNode.normalMatrix) {
      _inputNode = Matrix3Node();
    } else if (scope == Object3DNode.position || scope == Object3DNode.viewPosition) {
      _inputNode = Vector3Node();
    }

    return _inputNode.build(builder);
  }
}
