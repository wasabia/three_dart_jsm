import 'package:three_dart/three_dart.dart';

import 'index.dart';

class WebGPUObjects {
  WebGPUGeometries geometries;
  WebGPUInfo info;
  final updateMap = WeakMap();

  WebGPUObjects(this.geometries, this.info);

  update(object) {
    var geometry = object.geometry;
    var updateMap = this.updateMap;
    var frame = info.render["frame"];

    if (geometry is! BufferGeometry) {
      throw ('THREE.WebGPURenderer: This renderer only supports THREE.BufferGeometry for geometries.');
    }

    if (updateMap.get(geometry) != frame) {
      geometries.update(geometry);

      updateMap.set(geometry, frame);
    }
  }

  dispose() {
    updateMap.clear();
  }
}
