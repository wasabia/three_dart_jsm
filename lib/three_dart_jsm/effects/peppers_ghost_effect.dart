import 'package:three_dart/three3d/cameras/perspective_camera.dart';
import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart/three3d/math/quaternion.dart';
import 'package:three_dart/three3d/math/vector3.dart';
import 'package:three_dart/three_dart.dart' as three;

class PeppersGhostEffect {
  final three.WebGLRenderer renderer;
  late PerspectiveCamera _cameraB;
  late PerspectiveCamera _cameraF;
  late PerspectiveCamera _cameraL;
  late PerspectiveCamera _cameraR;
  late three.Vector3 _position;
  late three.Quaternion _quaternion;
  late three.Vector3 _scale;
  late double _halfWidth;
  late double _width;
  late double _height;

  late int cameraDistance;
  late bool reflectFromAbove;

  PeppersGhostEffect(this.renderer) {
    cameraDistance = 15;
    reflectFromAbove = false;
    _cameraF = PerspectiveCamera(); //front
    _cameraB = PerspectiveCamera(); //back
    _cameraL = PerspectiveCamera(); //left
    _cameraR = PerspectiveCamera(); //right

    _position = Vector3();
    _quaternion = Quaternion();
    _scale = Vector3();
    renderer.autoClear = false;
  }

  void setSize(double width, double height) {
    _halfWidth = width / 2;
    if (width < height) {
      _width = width / 3;
      _height = width / 3;
    } else {
      _width = height / 3;
      _height = height / 3;
    }

    renderer.setSize(width, height, false);
  }

  void render(three.Scene scene, three.Camera camera) {
    if (scene.matrixAutoUpdate == true) scene.updateMatrixWorld();

    if (camera.parent == null && camera.matrixAutoUpdate == true) {
      camera.updateMatrixWorld();
    }

    camera.matrixWorld.decompose(_position, _quaternion, _scale);

    // front
    _cameraF.position.copy(_position);
    _cameraF.quaternion.copy(_quaternion);
    _cameraF.translateZ(cameraDistance);
    _cameraF.lookAt(scene.position);

    // back
    _cameraB.position.copy(_position);
    _cameraB.quaternion.copy(_quaternion);
    _cameraB.translateZ(-(cameraDistance));
    _cameraB.lookAt(scene.position);
    _cameraB.rotation.z += 180 * (Math.pi / 180);

    // left
    _cameraL.position.copy(_position);
    _cameraL.quaternion.copy(_quaternion);
    _cameraL.translateX(-(cameraDistance));
    _cameraL.lookAt(scene.position);
    _cameraL.rotation.x += 90 * (Math.pi / 180);

    // right
    _cameraR.position.copy(_position);
    _cameraR.quaternion.copy(_quaternion);
    _cameraR.translateX(cameraDistance);
    _cameraR.lookAt(scene.position);
    _cameraR.rotation.x += 90 * (Math.pi / 180);

    renderer.clear();
    renderer.setScissorTest(true);

    renderer.setScissor(
        _halfWidth - (_width / 2), (_height * 2), _width, _height);
    renderer.setViewport(
        _halfWidth - (_width / 2), (_height * 2), _width, _height);

    if (reflectFromAbove) {
      renderer.render(scene, _cameraB);
    } else {
      renderer.render(scene, _cameraF);
    }

    renderer.setScissor(_halfWidth - (_width / 2), 0, _width, _height);
    renderer.setViewport(_halfWidth - (_width / 2), 0, _width, _height);

    if (reflectFromAbove) {
      renderer.render(scene, _cameraF);
    } else {
      renderer.render(scene, _cameraB);
    }

    renderer.setScissor(
        _halfWidth - (_width / 2) - _width, _height, _width, _height);
    renderer.setViewport(
        _halfWidth - (_width / 2) - _width, _height, _width, _height);

    if (reflectFromAbove) {
      renderer.render(scene, _cameraR);
    } else {
      renderer.render(scene, _cameraL);
    }

    renderer.setScissor(_halfWidth + (_width / 2), _height, _width, _height);
    renderer.setViewport(_halfWidth + (_width / 2), _height, _width, _height);

    if (reflectFromAbove) {
      renderer.render(scene, _cameraL);
    } else {
      renderer.render(scene, _cameraR);
    }

    renderer.setScissorTest(false);
  }
}
