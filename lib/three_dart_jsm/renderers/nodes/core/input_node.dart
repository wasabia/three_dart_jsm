import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class InputNode extends Node {
  InputNode([inputType]) : super(inputType) {
    this.inputType = inputType;

    constant = false;
  }

  setConst(value) {
    constant = value;

    return this;
  }

  getConst() {
    return constant;
  }

  getInputType(builder) {
    return inputType;
  }

  generateConst(builder) {
    return builder.getConst(getNodeType(builder), value);
  }

  @override
  generate([builder, output]) {
    var type = getNodeType(builder);

    if (constant == true) {
      return builder.format(generateConst(builder), type, output);
    } else {
      var inputType = getInputType(builder);

      var nodeUniform = builder.getUniformFromNode(this, builder.shaderStage, inputType);
      var propertyName = builder.getPropertyName(nodeUniform);

      return builder.format(propertyName, type, output);
    }
  }
}
