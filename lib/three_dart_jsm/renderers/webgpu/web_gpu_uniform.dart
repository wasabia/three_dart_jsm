import 'package:three_dart/three_dart.dart';

class WebGPUUniform {
  late String name;
  late dynamic value;

  late int boundary;
  late int itemSize;
  late int offset;

  WebGPUUniform(this.name, [this.value]) {
    boundary = 0; // used to build the uniform buffer according to the STD140 layout
    itemSize = 0;

    offset = 0; // this property is set by WebGPUUniformsGroup and marks the start position in the uniform buffer
  }

  setValue(value) {
    this.value = value;
  }

  getValue() {
    return value;
  }
}

class FloatUniform extends WebGPUUniform {
  FloatUniform(name, [value = 0]) : super(name, value) {
    boundary = 4;
    itemSize = 1;
  }
}

class Vector2Uniform extends WebGPUUniform {
  Vector2Uniform(name, [value]) : super(name, value) {
    this.value ??= Vector2();
    boundary = 8;
    itemSize = 2;
  }
}

class Vector3Uniform extends WebGPUUniform {
  Vector3Uniform(name, [value]) : super(name, value) {
    this.value ??= Vector3();

    boundary = 16;
    itemSize = 3;
  }
}

class Vector4Uniform extends WebGPUUniform {
  Vector4Uniform(name, [value]) : super(name, value) {
    this.value ??= Vector4(0, 0, 0, 0);

    boundary = 16;
    itemSize = 4;
  }
}

class ColorUniform extends WebGPUUniform {
  ColorUniform(name, [value]) : super(name, value) {
    this.value ??= Color();

    boundary = 16;
    itemSize = 3;
  }
}

class Matrix3Uniform extends WebGPUUniform {
  Matrix3Uniform(name, [value]) : super(name, value) {
    this.value = Matrix3();

    boundary = 48;
    itemSize = 12;
  }
}

class Matrix4Uniform extends WebGPUUniform {
  Matrix4Uniform(name, value) : super(name, value) {
    this.value ??= Matrix4();

    boundary = 64;
    itemSize = 16;
  }
}
