import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class IcosahedronGeometry extends Geometry {
  IcosahedronGeometry(num radius, int detail) : super() {
    parameters = {"radius": radius, "detail": detail};
    type = "IcosahedronGeometry";

    fromBufferGeometry(three.IcosahedronGeometry(radius, detail));
    mergeVertices();
  }
}
