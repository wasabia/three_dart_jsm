import 'package:three_dart/three3d/cameras/index.dart';
import 'package:three_dart/three3d/math/vector2.dart';
import 'package:three_dart/three_dart.dart' as three;

class StereoEffect {
  late final StereoCamera _stereo;
  late final Vector2 size;
  final three.WebGLRenderer renderer;

  StereoEffect(this.renderer) {
    _stereo = StereoCamera();
    _stereo.aspect = 0.5;
    size = Vector2();
  }

  void setEyeSeparation(eyeSep) {
    _stereo.eyeSep = eyeSep;
  }

  void setSize(width, height) {
    renderer.setSize(width, height);
  }

  void render(three.Scene scene, three.Camera camera) {
    if (scene.matrixAutoUpdate == true) {
      scene.updateMatrixWorld();
    }

    if (camera.parent == null && camera.matrixAutoUpdate == true) {
      camera.updateMatrixWorld();
    }

    _stereo.update(camera);

    renderer.getSize(size);

    if (renderer.autoClear) {
      renderer.clear();
    }
    renderer.setScissorTest(true);

    renderer.setScissor(0, 0, size.width / 2, size.height);
    renderer.setViewport(0, 0, size.width / 2, size.height);
    renderer.render(scene, _stereo.cameraL);

    renderer.setScissor(size.width / 2, 0, size.width / 2, size.height);
    renderer.setViewport(size.width / 2, 0, size.width / 2, size.height);
    renderer.render(scene, _stereo.cameraR);

    renderer.setScissorTest(false);
  }
}
