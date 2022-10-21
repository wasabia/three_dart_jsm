import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart';

/// Utility class for sampling weighted random points on the surface of a mesh.
///
/// Building the sampler is a one-time O(n) operation. Once built, any number of
/// random samples may be selected in O(logn) time. Memory usage is O(n).
///
/// References:
/// - http://www.joesfer.com/?p=84
/// - https://stackoverflow.com/a/4322940/1314762

class MeshSurfaceSampler {
  final _face = Triangle(null, null, null);
  final _color = Vector3.init();

  late BufferGeometry geometry;
  late Function randomFunction;
  late BufferAttribute positionAttribute;
  late BufferAttribute colorAttribute;
  BufferAttribute? weightAttribute;
  Float32Array? distribution;

  MeshSurfaceSampler(mesh) {
    var geometry = mesh.geometry;

    if (!geometry.isBufferGeometry || geometry.attributes.position.itemSize != 3) {
      throw ('THREE.MeshSurfaceSampler: Requires BufferGeometry triangle mesh.');
    }

    if (geometry.index) {
      print('THREE.MeshSurfaceSampler: Converting geometry to non-indexed BufferGeometry.');

      geometry = geometry.toNonIndexed();
    }

    this.geometry = geometry;
    randomFunction = Math.random;

    positionAttribute = this.geometry.getAttribute('position');
    colorAttribute = this.geometry.getAttribute('color');
    weightAttribute = null;

    distribution = null;
  }

  setWeightAttribute(name) {
    weightAttribute = name ? geometry.getAttribute(name) : null;

    return this;
  }

  build() {
    var positionAttribute = this.positionAttribute;
    var weightAttribute = this.weightAttribute;

    var faceWeights = Float32Array(positionAttribute.count ~/ 3);

    // Accumulate weights for each mesh face.

    for (var i = 0; i < positionAttribute.count; i += 3) {
      double faceWeight = 1;

      if (weightAttribute != null) {
        faceWeight = weightAttribute.getX(i)!.toDouble() +
            weightAttribute.getX(i + 1)!.toDouble() +
            weightAttribute.getX(i + 2)!.toDouble();
      }

      _face.a.fromBufferAttribute(positionAttribute, i);
      _face.b.fromBufferAttribute(positionAttribute, i + 1);
      _face.c.fromBufferAttribute(positionAttribute, i + 2);
      faceWeight *= _face.getArea();

      faceWeights[i ~/ 3] = faceWeight;
    }

    // Store cumulative total face weights in an array, where weight index
    // corresponds to face index.

    distribution = Float32Array(positionAttribute.count ~/ 3);

    double cumulativeTotal = 0;

    for (var i = 0; i < faceWeights.length; i++) {
      cumulativeTotal += faceWeights[i];

      distribution![i] = cumulativeTotal;
    }

    return this;
  }

  setRandomGenerator(randomFunction) {
    this.randomFunction = randomFunction;
    return this;
  }

  sample(targetPosition, targetNormal, targetColor) {
    var cumulativeTotal = distribution![distribution!.length - 1];

    var faceIndex = binarySearch(randomFunction() * cumulativeTotal);

    return sampleFace(faceIndex, targetPosition, targetNormal, targetColor);
  }

  binarySearch(x) {
    var dist = distribution!;
    var start = 0;
    var end = dist.length - 1;

    var index = -1;

    while (start <= end) {
      var mid = Math.ceil((start + end) / 2);

      if (mid == 0 || dist[mid - 1] <= x && dist[mid] > x) {
        index = mid;

        break;
      } else if (x < dist[mid]) {
        end = mid - 1;
      } else {
        start = mid + 1;
      }
    }

    return index;
  }

  sampleFace(faceIndex, targetPosition, targetNormal, targetColor) {
    var u = randomFunction();
    var v = randomFunction();

    if (u + v > 1) {
      u = 1 - u;
      v = 1 - v;
    }

    _face.a.fromBufferAttribute(positionAttribute, faceIndex * 3);
    _face.b.fromBufferAttribute(positionAttribute, faceIndex * 3 + 1);
    _face.c.fromBufferAttribute(positionAttribute, faceIndex * 3 + 2);

    targetPosition
        .set(0, 0, 0)
        .addScaledVector(_face.a, u)
        .addScaledVector(_face.b, v)
        .addScaledVector(_face.c, 1 - (u + v));

    if (targetNormal != null) {
      _face.getNormal(targetNormal);
    }

    if (targetColor != null) {
      _face.a.fromBufferAttribute(colorAttribute, faceIndex * 3);
      _face.b.fromBufferAttribute(colorAttribute, faceIndex * 3 + 1);
      _face.c.fromBufferAttribute(colorAttribute, faceIndex * 3 + 2);

      _color.set(0, 0, 0).addScaledVector(_face.a, u).addScaledVector(_face.b, v).addScaledVector(_face.c, 1 - (u + v));

      targetColor.r = _color.x;
      targetColor.g = _color.y;
      targetColor.b = _color.z;
    }

    return this;
  }
}
