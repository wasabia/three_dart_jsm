import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

proxy(target, handler) {
  return _Proxy(target, handler);
}

class _Proxy {
  late dynamic target;
  late dynamic handler;
  _Proxy(this.target, this.handler);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    String name = invocation.memberName.toString();

    name = name.replaceFirst(RegExp(r'^Symbol\("'), "");
    name = name.replaceFirst(RegExp(r'"\)$'), "");

    String prop = name;
    var node = target;

    if (prop == 'build') {
      var positional = invocation.positionalArguments;

      return node.build(positional[0], positional[1]);
    }

    // handler get
    if (node.getProperty(prop) == null) {
      if (RegExp(r"^[xyzwrgbastpq]{1,4}$").hasMatch(prop) == true) {
        // accessing properties ( swizzle )

        prop = prop
          ..replaceAll(RegExp(r"r|s"), 'x')
              .replaceAll(RegExp(r"g|t"), 'y')
              .replaceAll(RegExp(r"b|p"), 'z')
              .replaceAll(RegExp(r"a|q"), 'w');

        return shaderNodeObject(SplitNode(node, prop));
      } else if (RegExp(r"^\d+$").hasMatch(prop) == true) {
        // accessing array

        return shaderNodeObject(ArrayElementNode(node, FloatNode(num.parse(prop)).setConst(true)));
      }
    }

    return node.getProperty(prop);
  }
}

class NodeHandler {
  // factory NodeHandler( Function nodeClosure, params ) {
  // 	var inputs = params.shift();
  // 	return nodeClosure( ShaderNodeObjects( inputs ), params );
  // }

  get(node, prop) {
    if (prop is String && node[prop] == null) {
      if (RegExp(r"^[xyzwrgbastpq]{1,4}$").hasMatch(prop) == true) {
        // accessing properties ( swizzle )

        prop = prop
          ..replaceAll(RegExp(r"r|s"), 'x')
              .replaceAll(RegExp(r"g|t"), 'y')
              .replaceAll(RegExp(r"b|p"), 'z')
              .replaceAll(RegExp(r"a|q"), 'w');

        return shaderNodeObject(SplitNode(node, prop));
      } else if (RegExp(r"^\d+$").hasMatch(prop) == true) {
        // accessing array

        return shaderNodeObject(ArrayElementNode(node, FloatNode(num.parse(prop)).setConst(true)));
      }
    }

    return node[prop];
  }
}

var nodeObjects = WeakMap();

shaderNodeObject(obj) {
  if (obj is num) {
    return shaderNodeObject(FloatNode(obj).setConst(true));
  } else if (obj is Node) {
    var nodeObject = nodeObjects.get(obj);

    if (nodeObject == null) {
      nodeObject = proxy(obj, NodeHandler);
      nodeObjects.set(obj, nodeObject);
    }

    return nodeObject;
  }

  return obj;
}

shaderNodeObjects(objects) {
  for (var name in objects) {
    objects[name] = shaderNodeObject(objects[name]);
  }

  return objects;
}

shaderNodeArray(array) {
  var len = array.length;

  for (var i = 0; i < len; i++) {
    array[i] = shaderNodeObject(array[i]);
  }

  return array;
}

shaderNodeProxy(nodeClass, [scope, factor]) {
  print(" ShaderNode .ShaderNodeProxy NodeClass: $nodeClass ");

  // TODO

  // if ( scope == null ) {

  // 	return ( params ) {

  // 		return ShaderNodeObject( new NodeClass( ShaderNodeArray( params ) ) );

  // 	};

  // } else if ( factor == null ) {

  // 	return ( params ) {

  // 		return ShaderNodeObject( new NodeClass( scope, ShaderNodeArray( params ) ) );

  // 	};

  // } else {

  // 	factor = ShaderNodeObject( factor );

  // 	return ( params ) {

  // 		return ShaderNodeObject( new NodeClass( scope, ShaderNodeArray( params ), factor ) );

  // 	};

  // }
}

shaderNodeScript(jsFunc) {
  return (inputs, builder) {
    shaderNodeObjects(inputs);

    return shaderNodeObject(jsFunc(inputs, builder));
  };
}

// var ShaderNode = Proxy( ShaderNodeScript, NodeHandler );
var shaderNode = shaderNodeScript;

//
// Node Material Shader Syntax
//

var uniform = shaderNode((inputNode) {
  inputNode.setConst(false);

  return inputNode;
});

var nodeObject = (val) {
  return shaderNodeObject(val);
};

var float = (val) {
  return nodeObject(FloatNode(val).setConst(true));
};

var color = (params) {
  return nodeObject(ColorNode(Color(params)).setConst(true));
};

var join = (params) {
  return nodeObject(JoinNode(shaderNodeArray(params)));
};

var cond = (params) {
  return nodeObject(CondNode(shaderNodeArray(params)));
};

var vec2 = (params) {
  if (params[0]?.isNode == true) {
    return nodeObject(ConvertNode(params[0], 'vec2'));
  } else {
    // Providing one scalar value: This value is used for all components

    if (params.length == 1) {
      params[1] = params[0];
    }

    return nodeObject(Vector2Node(Vector2(params)).setConst(true));
  }
};

var vec3 = (params) {
  if (params[0]?.isNode == true) {
    return nodeObject(ConvertNode(params[0], 'vec3'));
  } else {
    // Providing one scalar value: This value is used for all components

    if (params.length == 1) {
      params[1] = params[2] = params[0];
    }

    return nodeObject(Vector3Node(Vector3(params)).setConst(true));
  }
};

var vec4 = (params) {
  if (params[0]?.isNode == true) {
    return nodeObject(ConvertNode(params[0], 'vec4'));
  } else {
    // Providing one scalar value: This value is used for all components

    if (params.length == 1) {
      params[1] = params[2] = params[3] = params[0];
    }

    return nodeObject(Vector4Node(Vector4(params)).setConst(true));
  }
};

var addTo = (varNode, params) {
  varNode.node = add(varNode.node, shaderNodeArray(params));

  return nodeObject(varNode);
};

var add = shaderNodeProxy(OperatorNode, '+');
var sub = shaderNodeProxy(OperatorNode, '-');
var mul = shaderNodeProxy(OperatorNode, '*');
var div = shaderNodeProxy(OperatorNode, '/');
var equal = shaderNodeProxy(OperatorNode, '==');
var assign = shaderNodeProxy(OperatorNode, '=');
var greaterThan = shaderNodeProxy(OperatorNode, '>');
var lessThanEqual = shaderNodeProxy(OperatorNode, '<=');
var and = shaderNodeProxy(OperatorNode, '&&');

var element = shaderNodeProxy(ArrayElementNode);

var normalGeometry = NormalNode(NormalNode.geometry);
var normalLocal = NormalNode(NormalNode.local);
var normalWorld = NormalNode(NormalNode.world);
var normalView = NormalNode(NormalNode.view);
var transformedNormalView = VarNode(NormalNode(NormalNode.view), 'TransformedNormalView', 'vec3');

var positionLocal = PositionNode(PositionNode.local);
var positionWorld = PositionNode(PositionNode.world);
var positionView = PositionNode(PositionNode.view);
var positionViewDirection = PositionNode(PositionNode.viewDirection);

var pi = Math.pi;
var pi2 = float(6.283185307179586);
var piHalf = float(1.5707963267948966);
var reciprocalPi = float(0.3183098861837907);
var reciprocalPi2 = float(0.15915494309189535);
var epsilon = float(1e-6);

var diffuseColor = PropertyNode('DiffuseColor', 'vec4');
var roughness = PropertyNode('Roughness', 'float');
var metalness = PropertyNode('Metalness', 'float');
var alphaTest = PropertyNode('AlphaTest', 'float');
var specularColor = PropertyNode('SpecularColor', 'color');

var abs = shaderNodeProxy(MathNode, 'abs');
var acos = shaderNodeProxy(MathNode, 'acos');
var asin = shaderNodeProxy(MathNode, 'asin');
var atan = shaderNodeProxy(MathNode, 'atan');
var ceil = shaderNodeProxy(MathNode, 'ceil');
var clamp = shaderNodeProxy(MathNode, 'clamp');
var cos = shaderNodeProxy(MathNode, 'cos');
var cross = shaderNodeProxy(MathNode, 'cross');
var degrees = shaderNodeProxy(MathNode, 'degrees');
var dFdx = shaderNodeProxy(MathNode, 'dFdx');
var dFdy = shaderNodeProxy(MathNode, 'dFdy');
var distance = shaderNodeProxy(MathNode, 'distance');
var dot = shaderNodeProxy(MathNode, 'dot');
var exp = shaderNodeProxy(MathNode, 'exp');
var exp2 = shaderNodeProxy(MathNode, 'exp2');
var faceforward = shaderNodeProxy(MathNode, 'faceforward');
var floor = shaderNodeProxy(MathNode, 'floor');
var fract = shaderNodeProxy(MathNode, 'fract');
var invert = shaderNodeProxy(MathNode, 'invert');
var inversesqrt = shaderNodeProxy(MathNode, 'inversesqrt');
var length = shaderNodeProxy(MathNode, 'length');
var log = shaderNodeProxy(MathNode, 'log');
var log2 = shaderNodeProxy(MathNode, 'log2');
var max = shaderNodeProxy(MathNode, 'max');
var min = shaderNodeProxy(MathNode, 'min');
var mix = shaderNodeProxy(MathNode, 'mix');
var mod = shaderNodeProxy(MathNode, 'mod');
var negate = shaderNodeProxy(MathNode, 'negate');
var normalize = shaderNodeProxy(MathNode, 'normalize');
var pow = shaderNodeProxy(MathNode, 'pow');
var pow2 = shaderNodeProxy(MathNode, 'pow', 2);
var pow3 = shaderNodeProxy(MathNode, 'pow', 3);
var pow4 = shaderNodeProxy(MathNode, 'pow', 4);
var radians = shaderNodeProxy(MathNode, 'radians');
var reflect = shaderNodeProxy(MathNode, 'reflect');
var refract = shaderNodeProxy(MathNode, 'refract');
var round = shaderNodeProxy(MathNode, 'round');
var saturate = shaderNodeProxy(MathNode, 'saturate');
var sign = shaderNodeProxy(MathNode, 'sign');
var sin = shaderNodeProxy(MathNode, 'sin');
var smoothstep = shaderNodeProxy(MathNode, 'smoothstep');
var sqrt = shaderNodeProxy(MathNode, 'sqrt');
var step = shaderNodeProxy(MathNode, 'step');
var tan = shaderNodeProxy(MathNode, 'tan');
var transformDirection = shaderNodeProxy(MathNode, 'transformDirection');
