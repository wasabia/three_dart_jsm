import 'package:three_dart/three_dart.dart' as three;

class Face3 {
  late int a;
  late int b;
  late int c;
  late three.Vector3 normal;
  late List<three.Vector3> vertexNormals;
  late three.Color color;
  late List<three.Color> vertexColors;
  late int materialIndex;

  Face3(this.a, this.b, this.c, normal, color, {this.materialIndex = 0}) {
    this.normal = (normal != null && normal.runtimeType == three.Vector3) ? normal : three.Vector3.init();
    vertexNormals = normal ?? [];

    this.color = (color != null && color.runtimeType == three.Color) ? color : three.Color(0, 0, 0);
    vertexColors = color ?? [];
  }

  clone() {
    return Face3(0, 0, 0, null, null).copy(this);
  }

  copy(Face3 source) {
    a = source.a;
    b = source.b;
    c = source.c;

    normal.copy(source.normal);
    color.copy(source.color);

    materialIndex = source.materialIndex;

    vertexNormals = List<three.Vector3>.filled(source.vertexNormals.length, three.Vector3.init());

    for (var i = 0, il = source.vertexNormals.length; i < il; i++) {
      vertexNormals[i] = source.vertexNormals[i].clone();
    }

    vertexColors = List<three.Color>.filled(source.vertexColors.length, three.Color(0, 0, 0));
    for (var i = 0, il = source.vertexColors.length; i < il; i++) {
      vertexColors[i] = source.vertexColors[i].clone();
    }

    return this;
  }
}
