import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

var LinearToLinear = ShaderNode((inputs) {
  return inputs.value;
});

var LinearTosRGB = ShaderNode((inputs) {
  var value = inputs.value;

  var rgb = value.rgb;

  var a = sub(mul(pow(value.rgb, vec3(0.41666)), 1.055), vec3(0.055));
  var b = mul(rgb, 12.92);
  var factor = vec3(lessThanEqual(rgb, vec3(0.0031308)));

  var rgbResult = mix(a, b, factor);

  return join([rgbResult.r, rgbResult.g, rgbResult.b, value.a]);
});

var EncodingLib = {"LinearToLinear": LinearToLinear, "LinearTosRGB": LinearTosRGB};

class ColorSpaceNode extends TempNode {
  static const String LINEAR_TO_LINEAR = 'LinearToLinear';
  static const String LINEAR_TO_SRGB = 'LinearTosRGB';

  late dynamic method;
  late dynamic node;

  ColorSpaceNode(method, node) : super('vec4') {
    this.method = method;

    this.node = node;
  }

  fromEncoding(encoding) {
    var method;

    if (encoding == LinearEncoding) {
      method = 'Linear';
    } else if (encoding == sRGBEncoding) {
      method = 'sRGB';
    }

    this.method = 'LinearTo' + method;

    return this;
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);

    var method = this.method;
    var node = this.node;

    if (method != ColorSpaceNode.LINEAR_TO_LINEAR) {
      var encodingFunctionNode = EncodingLib[method];

      return encodingFunctionNode({value: node}).build(builder, type);
    } else {
      return node.build(builder, type);
    }
  }
}
