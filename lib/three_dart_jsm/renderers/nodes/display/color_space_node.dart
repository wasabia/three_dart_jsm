import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

var linearToLinear = shaderNode((inputs) {
  return inputs.value;
});

var linearTosRGB = shaderNode((inputs) {
  var value = inputs.value;

  var rgb = value.rgb;

  var a = sub(mul(pow(value.rgb, vec3(0.41666)), 1.055), vec3(0.055));
  var b = mul(rgb, 12.92);
  var factor = vec3(lessThanEqual(rgb, vec3(0.0031308)));

  var rgbResult = mix(a, b, factor);

  return join([rgbResult.r, rgbResult.g, rgbResult.b, value.a]);
});

var encodingLib = {"LinearToLinear": linearToLinear, "LinearTosRGB": linearTosRGB};

class ColorSpaceNode extends TempNode {
  static const String linearToLinear = 'LinearToLinear';
  static const String linearToSRGB = 'LinearTosRGB';

  late dynamic method;
  late dynamic node;

  ColorSpaceNode(this.method, this.node) : super('vec4');

  fromEncoding(encoding) {
    var method;

    if (encoding == LinearEncoding) {
      method = 'Linear';
    } else if (encoding == sRGBEncoding) {
      method = 'sRGB';
    }

    this.method = 'LinearTo$method';

    return this;
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);

    var method = this.method;
    var node = this.node;

    if (method != ColorSpaceNode.linearToLinear) {
      var encodingFunctionNode = encodingLib[method];

      return encodingFunctionNode({value: node}).build(builder, type);
    } else {
      return node.build(builder, type);
    }
  }
}
