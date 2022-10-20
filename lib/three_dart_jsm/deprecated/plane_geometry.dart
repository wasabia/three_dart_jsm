import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class PlaneGeometry extends Geometry {
  PlaneGeometry(width, height, [widthSegments = 1, heightSegments = 1]) : super() {
    type = "PlaneGeometry";
    parameters = {
      "width": width,
      "height": height,
      "widthSegments": widthSegments,
      "heightSegments": heightSegments,
    };

    fromBufferGeometry(three.PlaneGeometry(width, height, widthSegments, heightSegments));
    mergeVertices();
  }
}
