import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart';

// import {
// 	Box3,
// 	Float32BufferAttribute,
// 	InstancedBufferGeometry,
// 	InstancedInterleavedBuffer,
// 	InterleavedBufferAttribute,
// 	Sphere,
// 	Vector3,
// 	WireframeGeometry
// } from '../../../build/three.module.js';

class LineSegmentsGeometry extends InstancedBufferGeometry {
  bool isLineSegmentsGeometry = true;

  LineSegmentsGeometry() : super() {
    type = "LineSegmentsGeometry";
    List<double> positions = [-1, 2, 0, 1, 2, 0, -1, 1, 0, 1, 1, 0, -1, 0, 0, 1, 0, 0, -1, -1, 0, 1, -1, 0];
    List<double> uvs = [-1, 2, 1, 2, -1, 1, 1, 1, -1, -1, 1, -1, -1, -2, 1, -2];
    List<int> index = [0, 2, 1, 2, 3, 1, 2, 4, 3, 4, 5, 3, 4, 6, 5, 6, 7, 5];

    setIndex(index);
    setAttribute('position', Float32BufferAttribute(Float32Array.from(positions), 3, false));
    setAttribute('uv', Float32BufferAttribute(Float32Array.from(uvs), 2, false));
  }

  @override
  LineSegmentsGeometry applyMatrix4(matrix) {
    var start = attributes["instanceStart"];
    var end = attributes["instanceEnd"];

    if (start != null) {
      start.applyMatrix4(matrix);

      end.applyMatrix4(matrix);

      start.needsUpdate = true;
    }

    if (boundingBox != null) {
      computeBoundingBox();
    }

    if (boundingSphere != null) {
      computeBoundingSphere();
    }

    return this;
  }

  setPositions(array) {
    var lineSegments;

    if (array is Float32Array) {
      lineSegments = array;
    } else if (array is List) {
      lineSegments = Float32Array.from(List<double>.from(array));
    }

    var instanceBuffer = InstancedInterleavedBuffer(lineSegments, 6, 1); // xyz, xyz

    setAttribute('instanceStart', InterleavedBufferAttribute(instanceBuffer, 3, 0, false)); // xyz
    setAttribute('instanceEnd', InterleavedBufferAttribute(instanceBuffer, 3, 3, false)); // xyz

    //

    computeBoundingBox();
    computeBoundingSphere();

    return this;
  }

  setColors(array) {
    var colors;

    if (array is Float32Array) {
      colors = array;
    } else if (array is List) {
      colors = Float32Array.from(List<double>.from(array));
    }

    var instanceColorBuffer = InstancedInterleavedBuffer(colors, 6, 1); // rgb, rgb

    setAttribute('instanceColorStart', InterleavedBufferAttribute(instanceColorBuffer, 3, 0, false)); // rgb
    setAttribute('instanceColorEnd', InterleavedBufferAttribute(instanceColorBuffer, 3, 3, false)); // rgb

    return this;
  }

  fromWireframeGeometry(geometry) {
    setPositions(geometry.attributes.position.array);

    return this;
  }

  fromEdgesGeometry(geometry) {
    setPositions(geometry.attributes.position.array);

    return this;
  }

  fromMesh(mesh) {
    fromWireframeGeometry(WireframeGeometry(mesh.geometry));

    // set colors, maybe

    return this;
  }

  fromLineSegments(lineSegments) {
    var geometry = lineSegments.geometry;

    if (geometry.isGeometry) {
      setPositions(geometry.vertices);
    } else if (geometry.isBufferGeometry) {
      setPositions(geometry.attributes.position.array); // assumes non-indexed

    }

    // set colors, maybe

    return this;
  }

  @override
  computeBoundingBox() {
    var box = Box3(null, null);

    boundingBox ??= Box3(null, null);

    var start = attributes["instanceStart"];
    var end = attributes["instanceEnd"];

    if (start != null && end != null) {
      boundingBox!.setFromBufferAttribute(start);

      box.setFromBufferAttribute(end);

      boundingBox!.union(box);
    }
  }

  @override
  computeBoundingSphere() {
    var vector = Vector3.init();

    boundingSphere ??= Sphere(null, null);

    if (boundingBox == null) {
      computeBoundingBox();
    }

    var start = attributes["instanceStart"];
    var end = attributes["instanceEnd"];

    if (start != null && end != null) {
      var center = boundingSphere!.center;

      boundingBox!.getCenter(center);

      num maxRadiusSq = 0;

      for (var i = 0, il = start.count; i < il; i++) {
        vector.fromBufferAttribute(start, i);
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(vector));

        vector.fromBufferAttribute(end, i);
        maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(vector));
      }

      boundingSphere!.radius = Math.sqrt(maxRadiusSq);

      if (boundingSphere?.radius == null) {
        print(
            'THREE.LineSegmentsGeometry.computeBoundingSphere(): Computed radius is NaN. The instanced position data is likely to have NaN values. ${this}');
      }
    }
  }

  // toJSON({}) {

  // 	// todo
  //   print(" toJSON TODO ...........");

  // }

  applyMatrix(matrix) {
    print('THREE.LineSegmentsGeometry: applyMatrix() has been renamed to applyMatrix4().');

    return applyMatrix4(matrix);
  }
}
