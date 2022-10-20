import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

class WebGPUInfo {
  late bool autoReset;
  late Map render;
  late Map memory;

  WebGPUInfo() {
    autoReset = true;

    render = {"frame": 0, "drawCalls": 0, "triangles": 0, "points": 0, "lines": 0};

    memory = {"geometries": 0, "textures": 0};
  }

  update(object, count, instanceCount) {
    render["drawCalls"]++;

    if (object is Mesh) {
      render["triangles"] += instanceCount * (count / 3);
    } else if (object is Points) {
      render["points"] += instanceCount * count;
    } else if (object is LineSegments) {
      render["lines"] += instanceCount * (count / 2);
    } else if (object is Line) {
      render["lines"] += instanceCount * (count - 1);
    } else {
      console.error('THREE.WebGPUInfo: Unknown object type.');
    }
  }

  reset() {
    render["frame"]++;
    render["drawCalls"] = 0;
    render["triangles"] = 0;
    render["points"] = 0;
    render["lines"] = 0;
  }

  dispose() {
    reset();

    render["frame"] = 0;

    memory["geometries"] = 0;
    memory["textures"] = 0;
  }
}
