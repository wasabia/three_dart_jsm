import 'package:three_dart/three_dart.dart';

import 'nurbs_utils.dart';

/// NURBS curve object
///
/// Derives from Curve, overriding getPoint and getTangent.
///
/// Implementation is based on (x, y [, z=0 [, w=1]]) control points with w=weight.
///
///*/

class NURBSCurve extends Curve {
  dynamic degree;
  dynamic knots;
  late List controlPoints;
  late int startKnot;
  late int endKnot;

  NURBSCurve(this.degree, this.knots /* array of reals */, controlPoints /* array of Vector(2|3|4) */,
      startKnot /* index in knots */, endKnot /* index in knots */
      )
      : super() {
    this.controlPoints = [];
    // Used by periodic NURBS to remove hidden spans
    this.startKnot = startKnot ?? 0;
    this.endKnot = endKnot ?? (knots.length - 1);

    for (var i = 0; i < controlPoints.length; ++i) {
      // ensure Vector4 for control points
      var point = controlPoints[i];
      this.controlPoints[i] = Vector4(point.x, point.y, point.z, point.w);
    }
  }

  @override
  getPoint(t, optionalTarget) {
    var point = optionalTarget ?? Vector3();

    var u = knots[startKnot] + t * (knots[endKnot] - knots[startKnot]); // linear mapping t->u

    // following results in (wx, wy, wz, w) homogeneous point
    var hpoint = calcBSplinePoint(degree, knots, controlPoints, u);

    if (hpoint.w != 1.0) {
      // project to 3D space: (wx, wy, wz, w) -> (x, y, z, 1)
      hpoint.divideScalar(hpoint.w);
    }

    return point.set(hpoint.x, hpoint.y, hpoint.z);
  }

  @override
  getTangent(t, [optionalTarget]) {
    var tangent = optionalTarget ?? Vector3();

    var u = knots[0] + t * (knots[knots.length - 1] - knots[0]);
    var ders = calcNURBSDerivatives(degree, knots, controlPoints, u, 1);
    tangent.copy(ders[1]).normalize();

    return tangent;
  }
}
