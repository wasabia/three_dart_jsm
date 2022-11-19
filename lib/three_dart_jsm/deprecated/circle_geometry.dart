import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class CircleGeometry extends Geometry {
  CircleGeometry(radius, segments, thetaStart, thetaLength) : super() {
    type = "CircleGeometry";
    parameters = {
      "radius": radius,
      "segments": segments,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength,
    };

    fromBufferGeometry(three.CircleGeometry(
      radius: radius,
      segments: segments,
      thetaStart: thetaStart,
      thetaLength: thetaLength,
    ));
    mergeVertices();
  }
}
