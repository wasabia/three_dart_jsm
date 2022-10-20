import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class CylinderGeometry extends Geometry {
  CylinderGeometry(
    radiusTop,
    radiusBottom,
    height,
    radialSegments,
    heightSegments,
    openEnded,
    thetaStart,
    thetaLength,
  ) : super() {
    type = "CylinderGeometry";
    parameters = {
      "radiusTop": radiusTop,
      "radiusBottom": radiusBottom,
      "height": height,
      "radialSegments": radialSegments,
      "heightSegments": heightSegments,
      "openEnded": openEnded,
      "thetaStart": thetaStart,
      "thetaLength": thetaLength,
    };

    fromBufferGeometry(three.CylinderGeometry(
      radiusTop,
      radiusBottom,
      height,
      radialSegments,
      heightSegments,
      openEnded,
      thetaStart,
      thetaLength,
    ));
    mergeVertices();
  }
}
