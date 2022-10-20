import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class DodecahedronGeometry extends Geometry {
  DodecahedronGeometry({radius = 0, detail = 0}) : super() {
    type = "DodecahedronGeometry";
    parameters = {"radius": radius, "detail": detail};

    fromBufferGeometry(three.DodecahedronGeometry(radius, detail));
    mergeVertices();
  }
}
