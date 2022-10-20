import '../index.dart';

class PositionNode extends Node {
  static const String GEOMETRY = 'geometry';
  static const String LOCAL = 'local';
  static const String WORLD = 'world';
  static const String VIEW = 'view';
  static const String VIEW_DIRECTION = 'viewDirection';

  late String scope;

  PositionNode([scope = PositionNode.LOCAL]) : super('vec3') {
    generateLength = 1;
    this.scope = scope;
  }

  @override
  getHash([builder]) {
    return "position-$scope";
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    var outputNode;

    if (scope == PositionNode.GEOMETRY) {
      outputNode = AttributeNode('position', 'vec3');
    } else if (scope == PositionNode.LOCAL) {
      outputNode = VaryNode(PositionNode(PositionNode.GEOMETRY));
    } else if (scope == PositionNode.WORLD) {
      var vertexPositionNode =
          MathNode(MathNode.TRANSFORM_DIRECTION, ModelNode(ModelNode.WORLD_MATRIX), PositionNode(PositionNode.LOCAL));
      outputNode = VaryNode(vertexPositionNode);
    } else if (scope == PositionNode.VIEW) {
      var vertexPositionNode = OperatorNode('*', ModelNode(ModelNode.VIEW_MATRIX), PositionNode(PositionNode.LOCAL));
      outputNode = VaryNode(vertexPositionNode);
    } else if (scope == PositionNode.VIEW_DIRECTION) {
      var vertexPositionNode = MathNode(MathNode.NEGATE, PositionNode(PositionNode.VIEW));
      outputNode = MathNode(MathNode.NORMALIZE, VaryNode(vertexPositionNode));
    }

    return outputNode.build(builder, getNodeType(builder));
  }
}
