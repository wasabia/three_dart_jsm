import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

import '../../nodes/index.dart';
import '../index.dart';

class WebGPUNodes {
  late WebGPURenderer renderer;
  late NodeFrame nodeFrame;
  late WeakMap builders;

  WebGPUNodes(this.renderer) {
    nodeFrame = NodeFrame();
    builders = WeakMap();
  }

  get(object, [lightNode]) {
    var nodeBuilder = builders.get(object);

    if (nodeBuilder == undefined) {
      nodeBuilder = WebGPUNodeBuilder(object, renderer, lightNode).build();

      builders.set(object, nodeBuilder);
    }

    return nodeBuilder;
  }

  remove(object) {
    builders.delete(object);
  }

  updateFrame() {
    // this.nodeFrame.update();
  }

  update(object, camera, [lightNode]) {
    var renderer = this.renderer;
    var material = object.material;

    var nodeBuilder = get(object, lightNode);
    var nodeFrame = this.nodeFrame;

    nodeFrame.material = material;
    nodeFrame.camera = camera;
    nodeFrame.object = object;
    nodeFrame.renderer = renderer;

    for (var node in nodeBuilder.updateNodes) {
      nodeFrame.updateNode(node);
    }
  }

  dispose() {
    builders = WeakMap();
  }
}
