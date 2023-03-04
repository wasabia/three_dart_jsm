import 'package:three_dart/three3d/cameras/orthographic_camera.dart';
import 'package:three_dart/three3d/cameras/stereo_camera.dart';
import 'package:three_dart/three3d/constants.dart';
import 'package:three_dart/three3d/geometries/plane_geometry.dart';
import 'package:three_dart/three3d/materials/shader_material.dart';
import 'package:three_dart/three3d/objects/mesh.dart';
import 'package:three_dart/three3d/renderers/web_gl_render_target.dart';
import 'package:three_dart/three_dart.dart' as three;

class ParallaxBarrierEffect {
  final three.WebGLRenderer renderer;
  late final OrthographicCamera _camera;
  late final three.Scene _scene;
  late final StereoCamera _stereo;
  late final dynamic _params;
  late final WebGLRenderTarget _renderTargetL;
  late final WebGLRenderTarget _renderTargetR;
  late final ShaderMaterial _material;
  late final Mesh mesh;

  ParallaxBarrierEffect(this.renderer) {
    _camera = OrthographicCamera(-1, 1, 1, -1, 0, 1);

    _scene = three.Scene();

    _stereo = StereoCamera();

    _params = {
      "minFilter": LinearFilter,
      "magFilter": NearestFilter,
      "format": RGBAFormat
    };

    _renderTargetL = WebGLRenderTarget(512, 512, _params);
    _renderTargetR = WebGLRenderTarget(512, 512, _params);

    _material = ShaderMaterial({
      "uniforms": {
        'mapLeft': {"value": _renderTargetL.texture},
        'mapRight': {"value": _renderTargetR.texture}
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
        'void main() {',
        '	vec2 uv = vUv;',
        '	if ( ( mod( gl_FragCoord.y, 2.0 ) ) > 1.00 ) {',
        '		gl_FragColor = texture2D( mapLeft, uv );',
        '	} else {',
        '		gl_FragColor = texture2D( mapRight, uv );',
        '	}',
        '}'
      ].join('\n')
    });

    mesh = Mesh(PlaneGeometry(2, 2), _material);
    _scene.add(mesh);
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
  }
}
