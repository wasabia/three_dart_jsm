import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three3d/cameras/orthographic_camera.dart';
import 'package:three_dart/three3d/constants.dart';
import 'package:three_dart/three3d/geometries/plane_geometry.dart';
import 'package:three_dart/three3d/materials/shader_material.dart';
import 'package:three_dart/three3d/math/matrix3.dart';
import 'package:three_dart/three3d/objects/mesh.dart';
import 'package:three_dart/three3d/renderers/web_gl_render_target.dart';
import 'package:three_dart/three_dart.dart' as three;

class AnaglyphEffect {
  final three.WebGLRenderer renderer;
  late Matrix3 colorMatrixLeft;
  late Matrix3 colorMatrixRight;
  late OrthographicCamera _camera;
  late three.Scene _scene;
  late three.StereoCamera _stereo;
  late dynamic _params;
  late WebGLRenderTarget _renderTargetL;
  late WebGLRenderTarget _renderTargetR;
  late ShaderMaterial _material;
  late Mesh _mesh;

  AnaglyphEffect(this.renderer, this.colorMatrixLeft, this.colorMatrixRight,
      width, height) {
    colorMatrixLeft = Matrix3().fromArray(Float32Array.fromList([
      0.456100,
      -0.0400822,
      -0.0152161,
      0.500484,
      -0.0378246,
      -0.0205971,
      0.176381,
      -0.0157589,
      -0.00546856
    ]));

    colorMatrixRight = Matrix3().fromArray(Float32Array.fromList([
      -0.0434706,
      0.378476,
      -0.0721527,
      -0.0879388,
      0.73364,
      -0.112961,
      -0.00155529,
      -0.0184503,
      1.2264
    ]));

    _camera = OrthographicCamera(-1, 1, 1, -1, 0, 1);

    _scene = three.Scene();

    _stereo = three.StereoCamera();

    _params = {
      "minFilter": LinearFilter,
      "magFilter": NearestFilter,
      "format": RGBAFormat
    };

    _renderTargetL = WebGLRenderTarget(width, height, _params);
    _renderTargetR = WebGLRenderTarget(width, height, _params);

    _material = ShaderMaterial({
      "uniforms": {
        'mapLeft': {"value": _renderTargetL.texture},
        'mapRight': {"value": _renderTargetR.texture},
        'colorMatrixLeft': {"value": colorMatrixLeft},
        'colorMatrixRight': {"value": colorMatrixRight}
      },
      "vertexShader": [
        'varying vec2 vUv;',
        'void main() {',
        '	vUv = vec2( uv.x, uv.y );',
        '	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );',
        '}'
      ].join('\n'),
      "fragmentShader": [
        'uniform sampler2D mapLeft;',
        'uniform sampler2D mapRight;',
        'varying vec2 vUv;',

        'uniform mat3 colorMatrixLeft;',
        'uniform mat3 colorMatrixRight;',

        // These functions implement sRGB linearization and gamma correction

        'float lin( float c ) {',
        '	return c <= 0.04045 ? c * 0.0773993808 :',
        '			pow( c * 0.9478672986 + 0.0521327014, 2.4 );',
        '}',

        'vec4 lin( vec4 c ) {',
        '	return vec4( lin( c.r ), lin( c.g ), lin( c.b ), c.a );',
        '}',

        'float dev( float c ) {',
        '	return c <= 0.0031308 ? c * 12.92',
        '			: pow( c, 0.41666 ) * 1.055 - 0.055;',
        '}',

        'void main() {',

        '	vec2 uv = vUv;',

        '	vec4 colorL = lin( texture2D( mapLeft, uv ) );',
        '	vec4 colorR = lin( texture2D( mapRight, uv ) );',

        '	vec3 color = clamp(',
        '			colorMatrixLeft * colorL.rgb +',
        '			colorMatrixRight * colorR.rgb, 0., 1. );',

        '	gl_FragColor = vec4(',
        '			dev( color.r ), dev( color.g ), dev( color.b ),',
        '			max( colorL.a, colorR.a ) );',

        '}'
      ].join('\n')
    });

    _mesh = Mesh(PlaneGeometry(2, 2), _material);
    _scene.add(_mesh);
  }

  void setSize(double width, double height) {
    renderer.setSize(width, height);

    var pixelRatio = renderer.getPixelRatio();

    _renderTargetL.setSize(
        (width * pixelRatio).round(), (height * pixelRatio).round());
    _renderTargetR.setSize(
        (width * pixelRatio).round(), (height * pixelRatio).round());
  }

  void render(three.Scene scene, three.Camera camera) {
    var currentRenderTarget = renderer.getRenderTarget();

    if (scene.matrixAutoUpdate == true) scene.updateMatrixWorld();

    if (camera.parent == null && camera.matrixAutoUpdate == true) {
      camera.updateMatrixWorld();
    }

    _stereo.update(camera);

    renderer.setRenderTarget(_renderTargetL);
    renderer.clear();
    renderer.render(scene, _stereo.cameraL);

    renderer.setRenderTarget(_renderTargetR);
    renderer.clear();
    renderer.render(scene, _stereo.cameraR);

    renderer.setRenderTarget(null);
    renderer.render(_scene, _camera);

    renderer.setRenderTarget(currentRenderTarget);
  }

  void dispose() {
    _renderTargetL.dispose();
    _renderTargetR.dispose();
    _mesh.geometry!.dispose();
    _mesh.material.dispose();
  }
  // Dubois matrices from https://citeseerx.ist.psu.edu/viewdoc/download?doi=

  // Dubois matrices from https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.7.6968&rep=rep1&type=pdf#page=4
}
