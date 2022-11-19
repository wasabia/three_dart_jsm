import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

import 'index.dart';

class WebGPUBackground {
  late WebGPURenderer renderer;
  late bool forceClear;

  WebGPUBackground(this.renderer) {
    forceClear = false;
  }

  clear() {
    forceClear = true;
  }

  update(scene) {
    var renderer = this.renderer;
    var background = (scene is Scene) ? scene.background : null;
    var forceClear = this.forceClear;

    if (background == null) {
      // no background settings, use clear color configuration from the renderer

    } else if (background.isColor == true) {
      // background is an opaque color

      forceClear = true;
    } else {
      console.error('THREE.WebGPURenderer: Unsupported background configuration.', background);
    }

    // configure render pass descriptor

    // TODO (WebGPU): implement

    // var renderPassDescriptor = renderer._renderPassDescriptor;
    // var colorAttachment = renderPassDescriptor.colorAttachments;
    // var depthStencilAttachment = renderPassDescriptor.depthStencilAttachment;

    if (renderer.autoClear == true || forceClear == true) {
      if (renderer.autoClearColor == true) {
        // colorAttachment.loadValue = { "r": _clearColor.r, "g": _clearColor.g, "b": _clearColor.b, "a": _clearAlpha };
        // colorAttachment.clearColor = GPUColor(
        // r: _clearColor.r.toDouble(),
        // g: _clearColor.g.toDouble(),
        // b: _clearColor.b.toDouble(),
        // a: _clearAlpha.toDouble());
      } else {
        // colorAttachment.loadValue = GPULoadOp.Load;
      }

      if (renderer.autoClearDepth == true) {
        // depthStencilAttachment.clearDepth = renderer._clearDepth.toDouble();

      } else {
        // depthStencilAttachment.depthLoadValue = GPULoadOp.Load;

      }

      if (renderer.autoClearStencil == true) {
        // depthStencilAttachment.clearStencil = renderer._clearStencil;

      } else {
        // depthStencilAttachment.stencilLoadValue = GPULoadOp.Load;

      }
    } else {
      // colorAttachment.loadValue = GPULoadOp.Load;
      // depthStencilAttachment.depthLoadValue = GPULoadOp.Load;
      // depthStencilAttachment.stencilLoadValue = GPULoadOp.Load;

    }

    this.forceClear = false;
  }
}
