import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';

import 'pass.dart';
import 'shader_pass.dart';

class EffectComposer {
  late WebGLRenderer renderer;
  late WebGLRenderTarget renderTarget1;
  late WebGLRenderTarget renderTarget2;

  late WebGLRenderTarget writeBuffer;
  late WebGLRenderTarget readBuffer;

  bool renderToScreen = true;

  double _pixelRatio = 1.0;
  late int _width;
  late int _height;

  List<Pass> passes = [];

  late Clock clock;

  late Pass copyPass;

  EffectComposer(WebGLRenderer renderer, WebGLRenderTarget? renderTarget) {
    this.renderer = renderer;

    if (renderTarget == null) {
      var parameters = {"minFilter": LinearFilter, "magFilter": LinearFilter, "format": RGBAFormat};

      var size = renderer.getSize(Vector2(null, null));
      _pixelRatio = renderer.getPixelRatio();
      _width = size.width.toInt();
      _height = size.height.toInt();

      renderTarget = WebGLRenderTarget(
          (_width * _pixelRatio).toInt(), (_height * _pixelRatio).toInt(), WebGLRenderTargetOptions(parameters));
    } else {
      _pixelRatio = 1;
      _width = renderTarget.width;
      _height = renderTarget.height;
    }

    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();
    renderTarget2.texture.name = 'EffectComposer.rt2';

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;

    renderToScreen = true;

    passes = [];

    // dependencies

    if (CopyShader == null) {
      print('THREE.EffectComposer relies on CopyShader');
    }

    if (ShaderPass == null) {
      print('THREE.EffectComposer relies on ShaderPass');
    }

    copyPass = ShaderPass(CopyShader, null);

    clock = Clock(false);
  }

  swapBuffers() {
    var tmp = readBuffer;
    readBuffer = writeBuffer;
    writeBuffer = tmp;
  }

  addPass(pass) {
    passes.add(pass);
    pass.setSize(_width * _pixelRatio, _height * _pixelRatio);
  }

  insertPass(pass, index) {
    splice(passes, index, 0, pass);
    pass.setSize(_width * _pixelRatio, _height * _pixelRatio);
  }

  removePass(pass) {
    var index = passes.indexOf(pass);

    if (index != -1) {
      splice(passes, index, 1);
    }
  }

  clearPass() {
    passes.clear();
  }

  isLastEnabledPass(passIndex) {
    for (var i = passIndex + 1; i < passes.length; i++) {
      if (passes[i].enabled) {
        return false;
      }
    }

    return true;
  }

  render(deltaTime) {
    // deltaTime value is in seconds

    deltaTime ??= clock.getDelta();

    var currentRenderTarget = renderer.getRenderTarget();

    var maskActive = false;

    var pass, i, il = passes.length;

    for (i = 0; i < il; i++) {
      pass = passes[i];

      if (pass.enabled == false) continue;

      pass.renderToScreen = (renderToScreen && isLastEnabledPass(i));
      pass.render(renderer, writeBuffer, readBuffer, deltaTime: deltaTime, maskActive: maskActive);

      if (pass.needsSwap) {
        if (maskActive) {
          var context = renderer.getContext();
          var stencil = renderer.state.buffers["stencil"];

          //context.stencilFunc( context.NOTEQUAL, 1, 0xffffffff );
          stencil.setFunc(context.NOTEQUAL, 1, 0xffffffff);

          copyPass.render(renderer, writeBuffer, readBuffer, deltaTime: deltaTime);

          //context.stencilFunc( context.EQUAL, 1, 0xffffffff );
          stencil.setFunc(context.EQUAL, 1, 0xffffffff);
        }

        swapBuffers();
      }

      if (pass.runtimeType.toString() == "MaskPass") {
        maskActive = true;
      } else if (pass.runtimeType.toString() == "ClearMaskPass") {
        maskActive = false;
      }
    }

    renderer.setRenderTarget(currentRenderTarget);
  }

  reset(renderTarget) {
    if (renderTarget == null) {
      var size = renderer.getSize(Vector2(null, null));
      _pixelRatio = renderer.getPixelRatio();
      _width = size.width.toInt();
      _height = size.height.toInt();

      renderTarget = renderTarget1.clone();
      renderTarget.setSize(_width * _pixelRatio, _height * _pixelRatio);
    }

    renderTarget1.dispose();
    renderTarget2.dispose();
    renderTarget1 = renderTarget;
    renderTarget2 = renderTarget.clone();

    writeBuffer = renderTarget1;
    readBuffer = renderTarget2;
  }

  setSize(int width, int height) {
    _width = width;
    _height = height;

    int effectiveWidth = (_width * _pixelRatio).toInt();
    int effectiveHeight = (_height * _pixelRatio).toInt();

    renderTarget1.setSize(effectiveWidth, effectiveHeight);
    renderTarget2.setSize(effectiveWidth, effectiveHeight);

    for (var i = 0; i < passes.length; i++) {
      passes[i].setSize(effectiveWidth, effectiveHeight);
    }
  }

  setPixelRatio(double pixelRatio) {
    _pixelRatio = pixelRatio;

    setSize(_width, _height);
  }
}
