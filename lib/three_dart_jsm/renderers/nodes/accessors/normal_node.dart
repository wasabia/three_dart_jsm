import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class NormalNode extends Node {
  static const String geometry = 'geometry';
  static const String local = 'local';
  static const String world = 'world';
  static const String view = 'view';

  late String scope;

  NormalNode([this.scope = NormalNode.local]) : super('vec3');

  @override
  getHash([builder]) {
    return "normal-$scope";
  }

  @override
  generate([builder, output]) {
    var scope = this.scope;

    var outputNode;

    if (scope == NormalNode.geometry) {
      outputNode = AttributeNode('normal', 'vec3');
    } else if (scope == NormalNode.local) {
      outputNode = VaryNode(NormalNode(NormalNode.geometry));
    } else if (scope == NormalNode.view) {
      var vertexNormalNode = OperatorNode('*', ModelNode(ModelNode.normalMatrix), NormalNode(NormalNode.local));
      outputNode = MathNode(MathNode.normalize, VaryNode(vertexNormalNode));
    } else if (scope == NormalNode.world) {
      // To use INVERSE_TRANSFORM_DIRECTION only inverse the param order like this: MathNode( ..., Vector, Matrix );
      var vertexNormalNode =
          MathNode(MathNode.transformDirection, NormalNode(NormalNode.view), CameraNode(CameraNode.viewMatrix));
      outputNode = MathNode(MathNode.normalize, VaryNode(vertexNormalNode));
    }

    return outputNode.build(builder);
  }
}
