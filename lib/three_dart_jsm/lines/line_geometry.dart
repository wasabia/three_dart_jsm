import 'package:flutter_gl/flutter_gl.dart';

import 'index.dart';

// import { LineSegmentsGeometry } from '../lines/LineSegmentsGeometry.js';

class LineGeometry extends LineSegmentsGeometry {
  bool isLineGeometry = true;

  LineGeometry() : super() {
    type = 'LineGeometry';
  }

  @override
  setPositions(array) {
    // converts [ x1, y1, z1,  x2, y2, z2, ... ] to pairs format

    int length = array.length - 3;
    var points = Float32Array(2 * length);

    for (var i = 0; i < length; i += 3) {
      points[2 * i] = array[i];
      points[2 * i + 1] = array[i + 1];
      points[2 * i + 2] = array[i + 2];

      points[2 * i + 3] = array[i + 3];
      points[2 * i + 4] = array[i + 4];
      points[2 * i + 5] = array[i + 5];
    }

    super.setPositions(points);

    return this;
  }

  @override
  setColors(array) {
    // converts [ r1, g1, b1,  r2, g2, b2, ... ] to pairs format

    int length = array.length - 3;
    var colors = Float32Array(2 * length);

    for (var i = 0; i < length; i += 3) {
      colors[2 * i] = array[i];
      colors[2 * i + 1] = array[i + 1];
      colors[2 * i + 2] = array[i + 2];

      colors[2 * i + 3] = array[i + 3];
      colors[2 * i + 4] = array[i + 4];
      colors[2 * i + 5] = array[i + 5];
    }

    super.setColors(colors);

    return this;
  }

  fromLine(line) {
    var geometry = line.geometry;

    if (geometry.isGeometry) {
      setPositions(geometry.vertices);
    } else if (geometry.isBufferGeometry) {
      setPositions(geometry.attributes.position.array); // assumes non-indexed

    }

    // set colors, maybe

    return this;
  }

  @override
  copy(source) {
    // todo

    return this;
  }
}
