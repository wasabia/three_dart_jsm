import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class NormalNode extends Node {
  static const String GEOMETRY = 'geometry';
  static const String LOCAL = 'local';
  static const String WORLD = 'world';
  static const String VIEW = 'view';

  late dynamic scope;

  NormalNode([scope = NormalNode.LOCAL]) : super('vec3') {
    this.scope = scope;
  }

  @override
  getHash([builder]) {
    return "normal-$scope";
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    var outputNode;

    if (scope == NormalNode.GEOMETRY) {
      outputNode = AttributeNode('normal', 'vec3');
    } else if (scope == NormalNode.LOCAL) {
      outputNode = VaryNode(NormalNode(NormalNode.GEOMETRY));
    } else if (scope == NormalNode.VIEW) {
      var vertexNormalNode = OperatorNode('*', ModelNode(ModelNode.NORMAL_MATRIX), NormalNode(NormalNode.LOCAL));
      outputNode = MathNode(MathNode.NORMALIZE, VaryNode(vertexNormalNode));
    } else if (scope == NormalNode.WORLD) {
      // To use INVERSE_TRANSFORM_DIRECTION only inverse the param order like this: MathNode( ..., Vector, Matrix );
      var vertexNormalNode =
          MathNode(MathNode.TRANSFORM_DIRECTION, NormalNode(NormalNode.VIEW), CameraNode(CameraNode.VIEW_MATRIX));
      outputNode = MathNode(MathNode.NORMALIZE, VaryNode(vertexNormalNode));
    }

    return outputNode.build(builder);
  }
}
