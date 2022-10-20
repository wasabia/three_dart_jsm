import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class TextureNode extends InputNode {
  late UVNode uv;
  late dynamic bias;

  TextureNode([value, uv, this.bias]) : super('texture') {
    this.value = value;
    this.uv = uv ?? UVNode();
  }

  @override
  generate([builder, output]) {
    var texture = value;

    if (!texture || texture.isTexture != true) {
      throw ('TextureNode: Need a three.js texture.');
    }

    var type = getNodeType(builder);

    var textureProperty = super.generate(builder, type);

    if (output == 'sampler2D' || output == 'texture2D') {
      return textureProperty;
    } else if (output == 'sampler') {
      return textureProperty + '_sampler';
    } else {
      var nodeData = builder.getDataFromNode(this);

      var snippet = nodeData.snippet;

      if (snippet == null) {
        var uvSnippet = uv.build(builder, 'vec2');
        var bias = this.bias;

        var biasSnippet;

        if (bias != null) {
          biasSnippet = bias.build(builder, 'float');
        }

        snippet = builder.getTexture(textureProperty, uvSnippet, biasSnippet);

        nodeData.snippet = snippet;
      }

      return builder.format(snippet, 'vec4', output);
    }
  }
}
