import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

/// Creates extruded geometry from a path shape.
///
/// parameters = {
///
///  curveSegments: <int>, // number of points on the curves
///  steps: <int>, // number of points for z-side extrusions / used for subdividing segments of extrude spline too
///  depth: <float>, // Depth to extrude the shape
///
///  bevelEnabled: <bool>, // turn on bevel
///  bevelThickness: <float>, // how deep into the original shape bevel goes
///  bevelSize: <float>, // how far from shape outline (including bevelOffset) is bevel
///  bevelOffset: <float>, // how far from shape outline does bevel start
///  bevelSegments: <int>, // number of bevel layers
///
///  extrudePath: <THREE.Curve> // curve to extrude shape along
///
///  UVGenerator: <Object> // object that provides UV generator functions
///
/// }

class ExtrudeGeometry extends Geometry {
  ExtrudeGeometry(shapes, options) : super() {
    type = "ExtrudeGeometry";
    parameters = {"shapes": shapes, "options": options};

    fromBufferGeometry(three.ExtrudeGeometry(shapes, options));
    mergeVertices();
  }

  @override
  toJSON() {
    var data = super.toJSON();

    var shapes = parameters["shapes"];
    var options = parameters["options"];

    return toJSON3(shapes, options, data);
  }

  Function toJSON3 = (shapes, options, data) {
    data.shapes = [];

    if (shapes is List) {
      for (var i = 0, l = shapes.length; i < l; i++) {
        var shape = shapes[i];

        data.shapes.add(shape.uuid);
      }
    } else {
      data.shapes.add(shapes.uuid);
    }

    if (options.extrudePath != null) data.options.extrudePath = options.extrudePath.toJSON();

    return data;
  };
}
