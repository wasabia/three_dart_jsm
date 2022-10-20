import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class ConvexGeometry extends Geometry {
  ConvexGeometry(points) : super() {
    type = "ConvexGeometry";
    fromBufferGeometry(three.ConvexGeometry(points ?? []));
    mergeVertices();
  }
}
