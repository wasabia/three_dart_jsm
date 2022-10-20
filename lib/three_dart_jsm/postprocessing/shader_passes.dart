import 'dart:convert';
import 'dart:typed_data';

import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/shaders/index.dart';

import 'pass.dart';

class ShaderPasses extends Pass {
  late dynamic textureID;
  @override
  late Map<String, dynamic> uniforms;
  @override
  late Material material;
  @override
  late FullScreenQuad fsQuad;
  late Color oldClearColor;
  late num oldClearAlpha;
  late bool oldAutoClear;
  late Color clearColor;
  List<dynamic>? passes;
  late Map<int, WebGLRenderTarget> renderTargetsPass;

  late int resx;
  late int resy;

  ShaderPasses(shader, textureID) : super() {
    this.textureID = (textureID != null) ? textureID : 'tDiffuse';

    uniforms = UniformsUtils.clone(shader["uniforms"]);
    passes = shader["passes"];

    clearColor = Color(0, 0, 0);
    oldClearColor = Color.fromHex(0xffffff);

    Map<String, dynamic> defines = {};
    defines.addAll(shader["defines"] ?? {});
    material = ShaderMaterial({
      "defines": defines,
      "uniforms": uniforms,
      "vertexShader": shader["vertexShader"],
      "fragmentShader": shader["fragmentShader"]
    });

    fsQuad = FullScreenQuad(material);
    renderTargetsPass = {};
  }

  @override
  render(renderer, writeBuffer, readBuffer, {num? deltaTime, bool? maskActive}) {
    renderer.getClearColor(oldClearColor);
    oldClearAlpha = renderer.getClearAlpha();
    oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    renderer.setClearColor(clearColor, alpha: 0.0);

    if (maskActive == true) renderer.state.buffers.stencil.setTest(false);

    if (uniforms[textureID] != null) {
      uniforms[textureID]["value"] = readBuffer.texture;
    }

    if (passes != null) {
      int i = 0;
      int lastPass = passes!.length - 1;
      WebGLRenderTarget? lastRenderTarget;
      for (Map<String, dynamic> pass in passes!) {
        material.uniforms["acPass"] = {"value": i};
        if (lastRenderTarget != null) {
          material.uniforms["acPassTexture"] = {"value": lastRenderTarget.texture};
        }

        material.needsUpdate = true;

        if (renderTargetsPass[i] == null) {
          var pars =
              WebGLRenderTargetOptions({"minFilter": LinearFilter, "magFilter": LinearFilter, "format": RGBAFormat});
          var renderTargetPass = WebGLRenderTarget(readBuffer.width, readBuffer.height, pars);
          renderTargetPass.texture.name = 'renderTargetPass$i';
          renderTargetPass.texture.generateMipmaps = false;
          renderTargetsPass[i] = renderTargetPass;
        }

        if (i >= lastPass) {
          if (renderToScreen) {
            renderPass(renderer, material, null, null, null, clear);
          } else {
            renderPass(renderer, material, writeBuffer, null, null, clear);
          }
        } else {
          renderPass(renderer, material, renderTargetsPass[i], null, null, clear);
        }

        lastRenderTarget = renderTargetsPass[i];

        i = i + 1;
      }
    } else {
      if (renderToScreen) {
        renderPass(renderer, material, null, null, null, clear);
      } else {
        renderPass(renderer, material, writeBuffer, null, null, clear);
      }
    }
  }

  renderPass(renderer, passMaterial, renderTarget, clearColor, clearAlpha, clear) {
    // print("renderPass passMaterial: ${passMaterial} renderTarget: ${renderTarget}  ");
    // print(passMaterial.uniforms);

    // setup pass state
    renderer.autoClear = false;

    renderer.setRenderTarget(renderTarget);

    if (clearColor != null) {
      renderer.setClearColor(clearColor);
      renderer.setClearAlpha(clearAlpha ?? 0.0);
      renderer.clear();
    }

    // TODO: Avoid using autoClear properties, see https://github.com/mrdoob/three.js/pull/15571#issuecomment-465669600
    if (clear) {
      renderer.clear(renderer.autoClearColor, renderer.autoClearDepth, renderer.autoClearStencil);
    }

    fsQuad.material = passMaterial;
    fsQuad.render(renderer);

    // restore original state
    renderer.autoClear = oldAutoClear;
    renderer.setClearColor(oldClearColor);
    renderer.setClearAlpha(oldClearAlpha);
  }
}
