import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class OperatorNode extends TempNode {
  late dynamic op;
  late Node aNode;
  late Node bNode;

  OperatorNode(this.op, aN, bN, [List? params]) : super() {
    generateLength = 2;

    if (params != null && params.isNotEmpty) {
      var finalBNode = bN;

      for (var i = 0; i < params.length; i++) {
        finalBNode = OperatorNode(op, finalBNode, params[i]);
      }

      bN = finalBNode;
    }

    aNode = aN;
    bNode = bN;
  }

  @override
  getNodeType([builder, output]) {
    var op = this.op;

    var aNode = this.aNode;
    var bNode = this.bNode;

    var typeA = aNode.getNodeType(builder);
    var typeB = bNode.getNodeType(builder);

    if (typeA == 'void' || typeB == 'void') {
      return 'void';
    } else if (op == '=') {
      return typeA;
    } else if (op == '==' || op == '&&') {
      return 'bool';
    } else if (op == '<=' || op == '>') {
      var length = builder.getTypeLength(output);

      return length > 1 ? "bvec$length" : 'bool';
    } else {
      if (typeA == 'float' && builder.isMatrix(typeB)) {
        return typeB;
      } else if (builder.isMatrix(typeA) && builder.isVector(typeB)) {
        // matrix x vector

        return builder.getVectorFromMatrix(typeA);
      } else if (builder.isVector(typeA) && builder.isMatrix(typeB)) {
        // vector x matrix

        return builder.getVectorFromMatrix(typeB);
      } else if (builder.getTypeLength(typeB) > builder.getTypeLength(typeA)) {
        // anytype x anytype: use the greater length vector

        return typeB;
      }

      return typeA;
    }
  }

  @override
  generate([builder, output]) {
    var op = this.op;

    var aNode = this.aNode;
    var bNode = this.bNode;

    var type = getNodeType(builder, output);

    var typeA;
    var typeB;

    if (type != 'void') {
      typeA = aNode.getNodeType(builder);
      typeB = bNode.getNodeType(builder);

      if (op == '=') {
        typeB = typeA;
      } else if (builder.isMatrix(typeA) && builder.isVector(typeB)) {
        // matrix x vector

        typeB = builder.getVectorFromMatrix(typeA);
      } else if (builder.isVector(typeA) && builder.isMatrix(typeB)) {
        // vector x matrix

        typeA = builder.getVectorFromMatrix(typeB);
      } else {
        // anytype x anytype

        typeA = typeB = type;
      }
    } else {
      typeA = typeB = type;
    }

    var a = aNode.build(builder, typeA);
    var b = bNode.build(builder, typeB);

    var outputLength = builder.getTypeLength(output);

    if (output != 'void') {
      if (op == '=') {
        builder.addFlowCode("$a ${this.op} $b");

        return a;
      } else if (op == '>' && outputLength > 1) {
        return "${builder.getMethod('greaterThan')}( $a, $b )";
      } else if (op == '<=' && outputLength > 1) {
        return "${builder.getMethod('lessThanEqual')}( $a, $b )";
      } else {
        return "( $a ${this.op} $b )";
      }
    } else if (typeA != 'void') {
      return "$a ${this.op} $b";
    }
  }
}
