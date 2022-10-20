import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class MaterialNode extends Node {
  static const String alphaTest = 'alphaTest';
  static const String color = 'color';
  static const String opacity = 'opacity';
  static const String specular = 'specular';
  static const String roughness = 'roughness';
  static const String metalness = 'metalness';

  late String scope;

  MaterialNode([this.scope = MaterialNode.color]) : super() {
    generateLength = 2;
  }

  @override
  getNodeType([builder, output]) {
    var scope = this.scope;
    var material = builder.context["material"];

    if (scope == MaterialNode.color) {
      return material.map != null ? 'vec4' : 'vec3';
    } else if (scope == MaterialNode.opacity) {
      return 'float';
    } else if (scope == MaterialNode.specular) {
      return 'vec3';
    } else if (scope == MaterialNode.roughness || scope == MaterialNode.metalness) {
      return 'float';
    }
  }

  @override
  generate([builder, output]) {
    var material = builder.context["material"];
    var scope = this.scope;

    var node;

    print(" ============ this ${this} generate scope: $scope  ");

    if (scope == MaterialNode.alphaTest) {
      node = MaterialReferenceNode('alphaTest', 'float');
    } else if (scope == MaterialNode.color) {
      var colorNode = MaterialReferenceNode('color', 'color');

      if (material.map != null && material.map != null && material.map.isTexture == true) {
        node = OperatorNode('*', colorNode, MaterialReferenceNode('map', 'texture'));
      } else {
        node = colorNode;
      }
    } else if (scope == MaterialNode.opacity) {
      var opacityNode = MaterialReferenceNode('opacity', 'float');

      if (material.alphaMap != null && material.alphaMap != null && material.alphaMap.isTexture == true) {
        node = OperatorNode('*', opacityNode, MaterialReferenceNode('alphaMap', 'texture'));
      } else {
        node = opacityNode;
      }
    } else if (scope == MaterialNode.specular) {
      var specularColorNode = MaterialReferenceNode('specularColor', 'color');

      if (material.specularColorMap != null && material.specularColorMap.isTexture == true) {
        node = OperatorNode('*', specularColorNode, MaterialReferenceNode('specularColorMap', 'texture'));
      } else {
        node = specularColorNode;
      }
    } else {
      var outputType = getNodeType(builder);

      node = MaterialReferenceNode(scope, outputType);
    }

    return node.build(builder, output);
  }
}
