import 'package:three_dart/extra/performance.dart';
import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class NodeFrame {
  late num time;
  late num deltaTime;
  late int frameId;
  num? startTime;
  late WeakMap updateMap;
  late dynamic renderer;
  late dynamic material;
  late dynamic camera;
  late dynamic object;
  late dynamic lastTime;

  NodeFrame() {
    time = 0;
    deltaTime = 0;

    frameId = 0;

    startTime = null;

    updateMap = WeakMap();

    renderer = null;
    material = null;
    camera = null;
    object = null;
  }

  updateNode(node) {
    if (node.updateType == NodeUpdateType.frame) {
      if (updateMap.get(node) != frameId) {
        updateMap.set(node, frameId);

        node.update(this);
      }
    } else if (node.updateType == NodeUpdateType.object) {
      node.update(this);
    }
  }

  update() {
    frameId++;

    lastTime ??= Performance.now();

    deltaTime = (Performance.now() - lastTime) / 1000;

    lastTime = Performance.now();

    time += deltaTime;
  }
}
