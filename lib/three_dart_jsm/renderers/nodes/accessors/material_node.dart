import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class MaterialNode extends Node {
  static const String ALPHA_TEST = 'alphaTest';
  static const String COLOR = 'color';
  static const String OPACITY = 'opacity';
  static const String SPECULAR = 'specular';
  static const String ROUGHNESS = 'roughness';
  static const String METALNESS = 'metalness';

  late String scope;

  MaterialNode([scope = MaterialNode.COLOR]) : super() {
    generateLength = 2;
    this.scope = scope;
  }

  @override
  getNodeType([builder, output]) {
    var scope = this.scope;
    var material = builder.context["material"];

    if (scope == MaterialNode.COLOR) {
      return material.map != null ? 'vec4' : 'vec3';
    } else if (scope == MaterialNode.OPACITY) {
      return 'float';
    } else if (scope == MaterialNode.SPECULAR) {
      return 'vec3';
    } else if (scope == MaterialNode.ROUGHNESS || scope == MaterialNode.METALNESS) {
      return 'float';
    }
  }

  @override
  generate([builder, output]) {
    var material = builder.context["material"];
    var scope = this.scope;

    var node;

    print(" ============ this ${this} generate scope: $scope  ");

    if (scope == MaterialNode.ALPHA_TEST) {
      node = MaterialReferenceNode('alphaTest', 'float');
    } else if (scope == MaterialNode.COLOR) {
      var colorNode = MaterialReferenceNode('color', 'color');

      if (material.map != null && material.map != null && material.map.isTexture == true) {
        node = OperatorNode('*', colorNode, MaterialReferenceNode('map', 'texture'));
      } else {
        node = colorNode;
      }
    } else if (scope == MaterialNode.OPACITY) {
      var opacityNode = MaterialReferenceNode('opacity', 'float');

      if (material.alphaMap != null && material.alphaMap != null && material.alphaMap.isTexture == true) {
        node = OperatorNode('*', opacityNode, MaterialReferenceNode('alphaMap', 'texture'));
      } else {
        node = opacityNode;
      }
    } else if (scope == MaterialNode.SPECULAR) {
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
