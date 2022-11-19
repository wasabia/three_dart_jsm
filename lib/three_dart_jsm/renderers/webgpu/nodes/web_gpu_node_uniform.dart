import '../index.dart';

class FloatNodeUniform extends FloatUniform {
  late dynamic nodeUniform;

  FloatNodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}

class Vector2NodeUniform extends Vector2Uniform {
  late dynamic nodeUniform;

  Vector2NodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}

class Vector3NodeUniform extends Vector3Uniform {
  late dynamic nodeUniform;

  Vector3NodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}

class Vector4NodeUniform extends Vector4Uniform {
  late dynamic nodeUniform;

  Vector4NodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}

class ColorNodeUniform extends ColorUniform {
  late dynamic nodeUniform;

  ColorNodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}

class Matrix3NodeUniform extends Matrix3Uniform {
  late dynamic nodeUniform;

  Matrix3NodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}

class Matrix4NodeUniform extends Matrix4Uniform {
  late dynamic nodeUniform;

  Matrix4NodeUniform(this.nodeUniform) : super(nodeUniform.name, nodeUniform.value);

  @override
  getValue() {
    return nodeUniform.value;
  }
}
