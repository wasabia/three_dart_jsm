import '../index.dart';

class PositionNode extends Node {
  static const String geometry = 'geometry';
  static const String local = 'local';
  static const String world = 'world';
  static const String view = 'view';
  static const String viewDirection = 'viewDirection';

  late String scope;

  PositionNode([this.scope = PositionNode.local]) : super('vec3') {
    generateLength = 1;
  }

  @override
  getHash([builder]) {
    return "position-$scope";
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    var outputNode;

    if (scope == PositionNode.geometry) {
      outputNode = AttributeNode('position', 'vec3');
    } else if (scope == PositionNode.local) {
      outputNode = VaryNode(PositionNode(PositionNode.geometry));
    } else if (scope == PositionNode.world) {
      var vertexPositionNode =
          MathNode(MathNode.transformDirection, ModelNode(ModelNode.worldMatrix), PositionNode(PositionNode.local));
      outputNode = VaryNode(vertexPositionNode);
    } else if (scope == PositionNode.view) {
      var vertexPositionNode = OperatorNode('*', ModelNode(ModelNode.viewMatrix), PositionNode(PositionNode.local));
      outputNode = VaryNode(vertexPositionNode);
    } else if (scope == PositionNode.viewDirection) {
      var vertexPositionNode = MathNode(MathNode.negate, PositionNode(PositionNode.view));
      outputNode = MathNode(MathNode.normalize, VaryNode(vertexPositionNode));
    }

    return outputNode.build(builder, getNodeType(builder));
  }
}
