import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

class WebGPUProperties {
  late WeakMap properties;

  WebGPUProperties() {
    properties = WeakMap();
  }

  get(object) {
    var map = properties.get(object);

    if (map == undefined) {
      map = {};
      properties.set(object, map);
    }

    return map;
  }

  remove(object) {
    properties.delete(object);
  }

  dispose() {
    properties = WeakMap();
  }
}
