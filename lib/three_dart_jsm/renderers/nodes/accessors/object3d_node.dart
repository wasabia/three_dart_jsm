import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Object3DNode extends Node {
  static const String VIEW_MATRIX = 'viewMatrix';
  static const String NORMAL_MATRIX = 'normalMatrix';
  static const String WORLD_MATRIX = 'worldMatrix';
  static const String POSITION = 'position';
  static const String VIEW_POSITION = 'viewPosition';

  late String scope;
  late dynamic object3d;
  late dynamic _inputNode;

  Object3DNode([scope = Object3DNode.VIEW_MATRIX, object3d]) : super() {
    this.scope = scope;
    this.object3d = object3d;

    updateType = NodeUpdateType.Object;

    _inputNode = null;
  }

  @override
  getNodeType([builder, output]) {
    var scope = this.scope;

    if (scope == Object3DNode.WORLD_MATRIX || scope == Object3DNode.VIEW_MATRIX) {
      return 'mat4';
    } else if (scope == Object3DNode.NORMAL_MATRIX) {
      return 'mat3';
    } else if (scope == Object3DNode.POSITION || scope == Object3DNode.VIEW_POSITION) {
      return 'vec3';
    }
  }

  @override
  update([frame]) {
    var object = object3d ?? frame.object;
    var inputNode = _inputNode;
    var camera = frame.camera;
    var scope = this.scope;

    if (scope == Object3DNode.VIEW_MATRIX) {
      inputNode.value = object.modelViewMatrix;
    } else if (scope == Object3DNode.NORMAL_MATRIX) {
      inputNode.value = object.normalMatrix;
    } else if (scope == Object3DNode.WORLD_MATRIX) {
      inputNode.value = object.matrixWorld;
    } else if (scope == Object3DNode.POSITION) {
      inputNode.value.setFromMatrixPosition(object.matrixWorld);
    } else if (scope == Object3DNode.VIEW_POSITION) {
      inputNode.value.setFromMatrixPosition(object.matrixWorld);

      inputNode.value.applyMatrix4(camera.matrixWorldInverse);
    }
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    if (scope == Object3DNode.WORLD_MATRIX || scope == Object3DNode.VIEW_MATRIX) {
      _inputNode = Matrix4Node();
    } else if (scope == Object3DNode.NORMAL_MATRIX) {
      _inputNode = Matrix3Node();
    } else if (scope == Object3DNode.POSITION || scope == Object3DNode.VIEW_POSITION) {
      _inputNode = Vector3Node();
    }

    return _inputNode.build(builder);
  }
}
