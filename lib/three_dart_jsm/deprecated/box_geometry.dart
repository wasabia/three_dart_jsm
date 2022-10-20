import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class BoxGeometry extends Geometry {
  BoxGeometry(width, height, depth, [widthSegments = 1, heightSegments = 1, depthSegments = 1]) : super() {
    type = "BoxGeometry";
    parameters = {
      "width": width,
      "height": height,
      "depth": depth,
      "widthSegments": widthSegments,
      "heightSegments": heightSegments,
      "depthSegments": depthSegments
    };

    fromBufferGeometry(three.BoxGeometry(width, height, depth, widthSegments, heightSegments, depthSegments));
    mergeVertices();
  }
}
