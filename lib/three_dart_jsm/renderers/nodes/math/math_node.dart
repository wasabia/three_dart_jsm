import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class MathNode extends TempNode {
  // 1 input

  static const String rad = 'radians';
  static const String deg = 'degrees';
  static const String exp = 'exp';
  static const String exp2 = 'exp2';
  static const String log = 'log';
  static const String log2 = 'log2';
  static const String sqrt = 'sqrt';
  static const String invSort = 'inversesqrt';
  static const String floor = 'floor';
  static const String ceil = 'ceil';
  static const String normalize = 'normalize';
  static const String fract = 'fract';
  static const String sin = 'sin';
  static const String cos = 'cos';
  static const String tan = 'tan';
  static const String asin = 'asin';
  static const String acos = 'acos';
  static const String atan = 'atan';
  static const String abs = 'abs';
  static const String sign = 'sign';
  static const String length = 'length';
  static const String negate = 'negate';
  static const String invert = 'invert';
  static const String dfdx = 'dFdx';
  static const String dfdy = 'dFdy';
  static const String saturate = 'saturate';
  static const String round = 'round';

  // 2 inputs

  static const String min = 'min';
  static const String max = 'max';
  static const String mod = 'mod';
  static const String step = 'step';
  static const String reflect = 'reflect';
  static const String distance = 'distance';
  static const String dot = 'dot';
  static const String cross = 'cross';
  static const String pow = 'pow';
  static const String transformDirection = 'transformDirection';

  // 3 inputs

  static const String mix = 'mix';
  static const String clamp = 'clamp';
  static const String refract = 'refract';
  static const String smoothStep = 'smoothstep';
  static const String faceForward = 'faceforward';

  late String method;
  late dynamic aNode;
  late dynamic bNode;
  late dynamic cNode;

  MathNode(this.method, this.aNode, [this.bNode, this.cNode]) : super();

  getInputType(builder) {
    var aType = aNode.getNodeType(builder);
    var bType = bNode ? bNode.getNodeType(builder) : null;
    var cType = cNode ? cNode.getNodeType(builder) : null;

    var aLen = builder.getTypeLength(aType);
    var bLen = builder.getTypeLength(bType);
    var cLen = builder.getTypeLength(cType);

    if (aLen > bLen && aLen > cLen) {
      return aType;
    } else if (bLen > cLen) {
      return bType;
    } else if (cLen > aLen) {
      return cType;
    }

    return aType;
  }

  @override
  getNodeType([builder, output]) {
    var method = this.method;

    if (method == MathNode.length || method == MathNode.distance || method == MathNode.dot) {
      return 'float';
    } else if (method == MathNode.cross) {
      return 'vec3';
    } else {
      return getInputType(builder);
    }
  }

  @override
  generate([builder, output]) {
    var method = this.method;

    var type = getNodeType(builder);
    var inputType = getInputType(builder);

    var a = aNode;
    var b = bNode;
    var c = cNode;

    var isWebGL = builder.renderer.isWebGLRenderer == true;

    if (isWebGL && (method == MathNode.dfdx || method == MathNode.dfdy) && output == 'vec3') {
      // Workaround for Adreno 3XX dFd*( vec3 ) bug. See #9988

      return JoinNode([
        MathNode(method, SplitNode(a, 'x')),
        MathNode(method, SplitNode(a, 'y')),
        MathNode(method, SplitNode(a, 'z'))
      ]).build(builder);
    } else if (method == MathNode.transformDirection) {
      // dir can be either a direction vector or a normal vector
      // upper-left 3x3 of matrix is assumed to be orthogonal

      var tA = a;
      var tB = b;

      if (builder.isMatrix(tA.getNodeType(builder))) {
        tB = ExpressionNode("${builder.getType('vec4')}( ${tB.build(builder, 'vec3')}, 0.0 )", 'vec4');
      } else {
        tA = ExpressionNode("${builder.getType('vec4')}( ${tA.build(builder, 'vec3')}, 0.0 )", 'vec4');
      }

      var mulNode = SplitNode(OperatorNode('*', tA, tB), 'xyz');

      return MathNode(MathNode.normalize, mulNode).build(builder);
    } else if (method == MathNode.saturate) {
      return "clamp( ${a.build(builder, inputType)}, 0.0, 1.0 )";
    } else if (method == MathNode.negate) {
      return '( -${a.build(builder, inputType)} )';
    } else if (method == MathNode.invert) {
      return '( 1.0 - ${a.build(builder, inputType)} )';
    } else {
      var params = [];

      if (method == MathNode.cross) {
        params.addAll([a.build(builder, type), b.build(builder, type)]);
      } else if (method == MathNode.step) {
        params.addAll([
          a.build(builder, builder.getTypeLength(a.getNodeType(builder)) == 1 ? 'float' : inputType),
          b.build(builder, inputType)
        ]);
      } else if ((isWebGL && (method == MathNode.min || method == MathNode.max)) || method == MathNode.mod) {
        params.addAll([
          a.build(builder, inputType),
          b.build(builder, builder.getTypeLength(b.getNodeType(builder)) == 1 ? 'float' : inputType)
        ]);
      } else if (method == MathNode.refract) {
        params.addAll([a.build(builder, inputType), b.build(builder, inputType), c.build(builder, 'float')]);
      } else if (method == MathNode.mix) {
        params.addAll([
          a.build(builder, inputType),
          b.build(builder, inputType),
          c.build(builder, builder.getTypeLength(c.getNodeType(builder)) == 1 ? 'float' : inputType)
        ]);
      } else {
        params.addAll([a.build(builder, inputType)]);

        if (c != null) {
          params.addAll([b.build(builder, inputType), c.build(builder, inputType)]);
        } else if (b != null) {
          params.add(b.build(builder, inputType));
        }
      }

      return "${builder.getMethod(method)}( ${params.join(', ')} )";
    }
  }
}
