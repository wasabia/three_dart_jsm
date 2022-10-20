import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class ModelViewProjectionNode extends Node {
  late PositionNode position;

  ModelViewProjectionNode([position]) : super('vec4') {
    generateLength = 1;
    this.position = position ?? PositionNode();
  }

  @override
  generate([builder, output]) {
    var position = this.position;

    var mvpMatrix = OperatorNode('*', CameraNode(CameraNode.PROJECTION_MATRIX), ModelNode(ModelNode.VIEW_MATRIX));
    var mvpNode = OperatorNode('*', mvpMatrix, position);

    var result = mvpNode.build(builder);

    return result;
  }
}
