import 'package:three_dart/three_dart.dart';

import 'pass.dart';

class RenderPass extends Pass {
  bool clearDepth = false;
  num clearAlpha = 0;
  Color? clearColor;
  Material? overrideMaterial;
  final Color _oldClearColor = Color(1, 1, 1);

  RenderPass(scene, camera, this.overrideMaterial, this.clearColor, num? clearAlpha) : super() {
    this.scene = scene;
    this.camera = camera;
    this.clearAlpha = clearAlpha ?? 0;

    clear = true;
    needsSwap = false;
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    var oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    var oldClearAlpha, oldOverrideMaterial;

    if (overrideMaterial != null) {
      oldOverrideMaterial = scene.overrideMaterial;

      scene.overrideMaterial = overrideMaterial;
    }

    if (clearColor != null) {
      renderer.getClearColor(_oldClearColor);
      oldClearAlpha = renderer.getClearAlpha();

      renderer.setClearColor(clearColor, alpha: clearAlpha);
    }

    if (clearDepth) {
      renderer.clearDepth();
    }

    renderer.setRenderTarget(renderToScreen ? null : readBuffer);

    // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
    if (clear) {
      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
    }
    renderer.render(scene, camera);

    if (clearColor != null) {
      renderer.setClearColor(_oldClearColor, alpha: oldClearAlpha);
    }

    if (overrideMaterial != null) {
      scene.overrideMaterial = oldOverrideMaterial;
    }

    renderer.autoClear = oldAutoClear;
  }
}
