import 'package:three_dart/three_dart.dart';

class Pass {
  // if set to true, the pass is processed by the composer
  bool enabled = true;

  // if set to true, the pass indicates to swap read and write buffer after rendering
  bool needsSwap = true;

  // if set to true, the pass clears its buffer before rendering
  bool clear = false;

  // if set to true, the result of the pass is rendered to screen. This is set automatically by EffectComposer.
  bool renderToScreen = false;

  late Object3D scene;
  late Camera camera;

  late Map<String, dynamic> uniforms;
  late Material material;
  late FullScreenQuad fsQuad;

  Pass();

  setProperty(String key, dynamic newValue) {
    // print(" Pass setProperty key: ${key} ");
    uniforms[key] = {"value": newValue};
  }

  setSize(int width, int height) {}

  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    throw ('THREE.Pass: .render() must be implemented in derived pass.');
  }
}

// Helper for passes that need to fill the viewport with a single quad.

// Important: It's actually a hack to put FullScreenQuad into the Pass namespace. This is only
// done to make examples/js code work. Normally, FullScreenQuad should be exported
// from this module like Pass.

class FullScreenQuad {
  Camera camera = OrthographicCamera(-1, 1, 1, -1, 0, 1);
  BufferGeometry geometry = PlaneGeometry(2, 2);

  late Object3D _mesh;

  FullScreenQuad(material) {
    geometry.name = "FullScreenQuadGeometry";

    _mesh = Mesh(geometry, material);
  }

  set mesh(value) {
    _mesh = value;
  }

  get material => _mesh.material;

  set material(value) {
    _mesh.material = value;
  }

  render(renderer) {
    renderer.render(_mesh, camera);
  }

  dispose() {
    _mesh.geometry!.dispose();
  }
}
