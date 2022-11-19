import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

import 'index.dart';

class _Stages {
  Map vertex;
  Map fragment;
  _Stages({required this.vertex, required this.fragment});
}

extension MapExt on Map {
  get(key) {
    return this[key];
  }

  set(key, value) {
    this[key] = value;
  }

  delete(key) {
    remove(key);
  }
}

// TODO (WebGPU): implement

class WebGPURenderPipelines {
  late WebGPURenderer renderer;
  // late GPUDevice device;
  late int sampleCount;
  late WebGPUNodes nodes;
  late dynamic bindings;
  late List pipelines;
  late WeakMap objectCache;
  late _Stages _stages;

  WebGPURenderPipelines(this.renderer, device, this.sampleCount, this.nodes, [this.bindings]) {
    // this.device = device;

    pipelines = [];
    objectCache = WeakMap();

    _stages = _Stages(vertex: {}, fragment: {});
  }

  get(object) {
    // var device = this.device;
    var material = object.material;

    Map<String, dynamic> cache = _getCache(object);

    var currentPipeline;

    if (_needsUpdate(object, cache)) {
      // release previous cache

      if (cache["currentPipeline"] != undefined) {
        _releaseObject(object);
      }

      // get shader

      WebGPUNodeBuilder nodeBuilder = nodes.get(object);

      // programmable stages

      var stageVertex = _stages.vertex.get(nodeBuilder.vertexShader);

      if (stageVertex == undefined) {
        // stageVertex = new WebGPUProgrammableStage(device, nodeBuilder.vertexShader, 'vertex');
        _stages.vertex.set(nodeBuilder.vertexShader, stageVertex);
      }

      var stageFragment = _stages.fragment.get(nodeBuilder.fragmentShader);

      if (stageFragment == undefined) {
        // stageFragment = new WebGPUProgrammableStage(device, nodeBuilder.fragmentShader, 'fragment');
        _stages.fragment.set(nodeBuilder.fragmentShader, stageFragment);
      }

      // determine render pipeline

      currentPipeline = _acquirePipeline(stageVertex, stageFragment, object, nodeBuilder);

      cache["currentPipeline"] = currentPipeline;

      // keep track of all used times

      currentPipeline.usedTimes++;
      stageVertex.usedTimes++;
      stageFragment.usedTimes++;

      // events

      material.addEventListener('dispose', cache["dispose"]);
    } else {
      currentPipeline = cache["currentPipeline"];
    }

    return currentPipeline;
  }

  dispose() {
    pipelines = [];
    objectCache = WeakMap();
    // this.shaderModules = _Stages(
    // 	vertex: new Map(),
    // 	fragment: new Map()
    // );
  }

  WebGPURenderPipeline _acquirePipeline(stageVertex, stageFragment, object, nodeBuilder) {
    var pipeline;
    var pipelines = this.pipelines;

    // check for existing pipeline

    var cacheKey = _computeCacheKey(stageVertex, stageFragment, object);

    for (var i = 0, il = pipelines.length; i < il; i++) {
      var preexistingPipeline = pipelines[i];

      if (preexistingPipeline.cacheKey == cacheKey) {
        pipeline = preexistingPipeline;
        break;
      }
    }

    if (pipeline == undefined) {
      // pipeline = new WebGPURenderPipeline(this.device, this.renderer, this.sampleCount);
      // pipeline.init(cacheKey, stageVertex, stageFragment, object, nodeBuilder);

      // pipelines.add(pipeline);
    }

    return pipeline;
  }

  _computeCacheKey(stageVertex, stageFragment, object) {
    var material = object.material;
    var renderer = this.renderer;

    var parameters = [
      stageVertex.id,
      stageFragment.id,
      material.transparent,
      material.blending,
      material.premultipliedAlpha,
      material.blendSrc,
      material.blendDst,
      material.blendEquation,
      material.blendSrcAlpha,
      material.blendDstAlpha,
      material.blendEquationAlpha,
      material.colorWrite,
      material.depthWrite,
      material.depthTest,
      material.depthFunc,
      material.stencilWrite,
      material.stencilFunc,
      material.stencilFail,
      material.stencilZFail,
      material.stencilZPass,
      material.stencilFuncMask,
      material.stencilWriteMask,
      material.side,
      sampleCount,
      renderer.getCurrentEncoding(),
      renderer.getCurrentColorFormat(),
      renderer.getCurrentDepthStencilFormat()
    ];

    return parameters.join();
  }

  _getCache(object) {
    var cache = objectCache.get(object);

    if (cache == null) {
      Map<String, dynamic> cacheMap = {
        "dispose": () {
          _releaseObject(object);

          objectCache.delete(object);

          object.material.removeEventListener('dispose', cache.dispose);
        }
      };

      cache = cacheMap;

      objectCache.set(object, cache);
    }

    return cache;
  }

  _releaseObject(object) {
    var cache = objectCache.get(object);

    _releasePipeline(cache.currentPipeline);
    cache.currentPipeline = null;

    nodes.remove(object);
    bindings.remove(object);
  }

  _releasePipeline(pipeline) {
    if (--pipeline.usedTimes == 0) {
      var pipelines = this.pipelines;

      var i = pipelines.indexOf(pipeline);
      pipelines[i] = pipelines[pipelines.length - 1];
      pipelines.removeLast();

      _releaseStage(pipeline.stageVertex);
      _releaseStage(pipeline.stageFragment);
    }
  }

  _releaseStage(stage) {
    if (--stage.usedTimes == 0) {
      var code = stage.code;
      var type = stage.type;

      if (type == "verter") {
        _stages.vertex.delete(code);
      } else if (type == "fragment") {
        _stages.fragment.delete(code);
      }
    }
  }

  _needsUpdate(object, Map<String, dynamic> cache) {
    var material = object.material;

    var needsUpdate = false;

    // check material state

    if (cache["material"] != material ||
        cache["materialVersion"] != material.version ||
        cache["transparent"] != material.transparent ||
        cache["blending"] != material.blending ||
        cache["premultipliedAlpha"] != material.premultipliedAlpha ||
        cache["blendSrc"] != material.blendSrc ||
        cache["blendDst"] != material.blendDst ||
        cache["blendEquation"] != material.blendEquation ||
        cache["blendSrcAlpha"] != material.blendSrcAlpha ||
        cache["blendDstAlpha"] != material.blendDstAlpha ||
        cache["blendEquationAlpha"] != material.blendEquationAlpha ||
        cache["colorWrite"] != material.colorWrite ||
        cache["depthWrite"] != material.depthWrite ||
        cache["depthTest"] != material.depthTest ||
        cache["depthFunc"] != material.depthFunc ||
        cache["stencilWrite"] != material.stencilWrite ||
        cache["stencilFunc"] != material.stencilFunc ||
        cache["stencilFail"] != material.stencilFail ||
        cache["stencilZFail"] != material.stencilZFail ||
        cache["stencilZPass"] != material.stencilZPass ||
        cache["stencilFuncMask"] != material.stencilFuncMask ||
        cache["stencilWriteMask"] != material.stencilWriteMask ||
        cache["side"] != material.side) {
      cache["material"] = material;
      cache["materialVersion"] = material.version;
      cache["transparent"] = material.transparent;
      cache["blending"] = material.blending;
      cache["premultipliedAlpha"] = material.premultipliedAlpha;
      cache["blendSrc"] = material.blendSrc;
      cache["blendDst"] = material.blendDst;
      cache["blendEquation"] = material.blendEquation;
      cache["blendSrcAlpha"] = material.blendSrcAlpha;
      cache["blendDstAlpha"] = material.blendDstAlpha;
      cache["blendEquationAlpha"] = material.blendEquationAlpha;
      cache["colorWrite"] = material.colorWrite;
      cache["depthWrite"] = material.depthWrite;
      cache["depthTest"] = material.depthTest;
      cache["depthFunc"] = material.depthFunc;
      cache["stencilWrite"] = material.stencilWrite;
      cache["stencilFunc"] = material.stencilFunc;
      cache["stencilFail"] = material.stencilFail;
      cache["stencilZFail"] = material.stencilZFail;
      cache["stencilZPass"] = material.stencilZPass;
      cache["stencilFuncMask"] = material.stencilFuncMask;
      cache["stencilWriteMask"] = material.stencilWriteMask;
      cache["side"] = material.side;

      needsUpdate = true;
    }

    // check renderer state

    var renderer = this.renderer;

    var encoding = renderer.getCurrentEncoding();
    var colorFormat = renderer.getCurrentColorFormat();
    var depthStencilFormat = renderer.getCurrentDepthStencilFormat();

    if (cache["sampleCount"] != sampleCount ||
        cache["encoding"] != encoding ||
        cache["colorFormat"] != colorFormat ||
        cache["depthStencilFormat"] != depthStencilFormat) {
      cache["sampleCount"] = sampleCount;
      cache["encoding"] = encoding;
      cache["colorFormat"] = colorFormat;
      cache["depthStencilFormat"] = depthStencilFormat;

      needsUpdate = true;
    }

    return needsUpdate;
  }
}
