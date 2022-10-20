import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

/// Text = 3D Text
///
/// parameters = {
///  font: <THREE.Font>, // font
///
///  size: <float>, // size of the text
///  height: <float>, // thickness to extrude text
///  curveSegments: <int>, // number of points on the curves
///
///  bevelEnabled: <bool>, // turn on bevel
///  bevelThickness: <float>, // how deep into text bevel goes
///  bevelSize: <float>, // how far from text outline (including bevelOffset) is bevel
///  bevelOffset: <float> // how far from text outline does bevel start
/// }

class TextGeometry extends Geometry {
  TextGeometry(text, parameters) : super() {
    this.parameters = {"text": text, "parameters": parameters};
    type = 'TextGeometry';
    fromBufferGeometry(three.TextGeometry(text, parameters));
    mergeVertices();
  }
}
