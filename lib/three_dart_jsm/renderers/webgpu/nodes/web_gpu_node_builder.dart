import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

import '../../nodes/index.dart';
import '../index.dart';

var wgslTypeLib = {
  'float': 'f32',
  'int': 'i32',
  'vec2': 'vec2<f32>',
  'vec3': 'vec3<f32>',
  'vec4': 'vec4<f32>',
  'uvec4': 'vec4<u32>',
  'bvec3': 'vec3<bool>',
  'mat3': 'mat3x3<f32>',
  'mat4': 'mat4x4<f32>'
};

var wgslMethods = {'dFdx': 'dpdx', 'dFdy': 'dpdy'};

var wgslPolyfill = {
  "lessThanEqual": CodeNode("""
fn lessThanEqual( a : vec3<f32>, b : vec3<f32> ) -> vec3<bool> {

	return vec3<bool>( a.x <= b.x, a.y <= b.y, a.z <= b.z );

}
"""),
  "mod": CodeNode("""
fn mod( x : f32, y : f32 ) -> f32 {

	return x - y * floor( x / y );

}
"""),
  "repeatWrapping": CodeNode("""
fn repeatWrapping( uv : vec2<f32>, dimension : vec2<i32> ) -> vec2<i32> {

	var uvScaled = vec2<i32>( uv * vec2<f32>( dimension ) );

	return ( ( uvScaled % dimension ) + dimension ) % dimension;

}
"""),
  "inversesqrt": CodeNode("""
fn inversesqrt( x : f32 ) -> f32 {

	return 1.0 / sqrt( x );

}
""")
};

class WebGPUNodeBuilder extends NodeBuilder {
  late Map uniformsGroup;
  late dynamic lightNode;

  late Map bindings;
  late Map bindingsOffset;

  WebGPUNodeBuilder(object, renderer, [this.lightNode]) : super(object, renderer, null) {
    bindings = {"vertex": [], "fragment": []};
    bindingsOffset = {"vertex": 0, "fragment": 0};

    uniformsGroup = {};

    _parseObject();
  }

  _parseObject() {
    var object = this.object;
    var material = this.material;

    // parse inputs

    if (material is MeshStandardMaterial ||
        material is MeshBasicMaterial ||
        material is PointsMaterial ||
        material is LineBasicMaterial) {
      var lightNode = material.lightNode;

      // VERTEX STAGE

      Node vertex = PositionNode(PositionNode.geometry);

      if (lightNode == null && this.lightNode != null && this.lightNode.hasLights == true) {
        lightNode = this.lightNode;
      }

      if (material.positionNode != null && material.positionNode.isNode) {
        var assignPositionNode = OperatorNode('=', PositionNode(PositionNode.local), material.positionNode);

        vertex = BypassNode(vertex, assignPositionNode);
      }

      if (object is SkinnedMesh) {
        vertex = BypassNode(vertex, SkinningNode(object));
      }

      context["vertex"] = vertex;

      addFlow('vertex', VarNode(ModelViewProjectionNode(), 'MVP', 'vec4'));

      // COLOR

      var colorNode;

      if (material.colorNode != null && material.colorNode is Node) {
        colorNode = material.colorNode;
      } else {
        colorNode = MaterialNode(MaterialNode.color);
      }

      colorNode = addFlow('fragment', VarNode(colorNode, 'Color', 'vec4'));

      var diffuseColorNode = addFlow('fragment', VarNode(colorNode, 'DiffuseColor', 'vec4'));

      // OPACITY

      var opacityNode;

      if (material.opacityNode != null && material.opacityNode is Node) {
        opacityNode = material.opacityNode;
      } else {
        opacityNode = VarNode(MaterialNode(MaterialNode.opacity));
      }

      addFlow('fragment', VarNode(opacityNode, 'OPACITY', 'float'));

      addFlow('fragment', ExpressionNode('DiffuseColor.a = DiffuseColor.a * OPACITY;'));

      // ALPHA TEST

      var alphaTest;

      if (material.alphaTestNode != null && material.alphaTestNode is Node) {
        alphaTest = material.alphaTestNode;
      } else if (material.alphaTest > 0) {
        alphaTest = MaterialNode(MaterialNode.alphaTest);
      }

      if (alphaTest != null) {
        addFlow('fragment', VarNode(alphaTest, 'AlphaTest', 'float'));

        addFlow('fragment', ExpressionNode('if ( DiffuseColor.a <= AlphaTest ) { discard; }'));
      }

      if (material is MeshStandardMaterial) {
        // METALNESS

        var metalnessNode;

        if (material.metalnessNode != null && material.metalnessNode.isNode) {
          metalnessNode = material.metalnessNode;
        } else {
          metalnessNode = MaterialNode(MaterialNode.metalness);
        }

        addFlow('fragment', VarNode(metalnessNode, 'Metalness', 'float'));

        addFlow('fragment',
            ExpressionNode('DiffuseColor = vec4<f32>( DiffuseColor.rgb * ( 1.0 - Metalness ), DiffuseColor.a );'));

        // ROUGHNESS

        var roughnessNode;

        if (material.roughnessNode && material.roughnessNode.isNode) {
          roughnessNode = material.roughnessNode;
        } else {
          roughnessNode = MaterialNode(MaterialNode.roughness);
        }

        roughnessNode = getRoughness({roughness: roughnessNode});

        addFlow('fragment', VarNode(roughnessNode, 'Roughness', 'float'));

        // SPECULAR_TINT

        addFlow(
            'fragment',
            VarNode(
                ExpressionNode('mix( vec3<f32>( 0.04 ), Color.rgb, Metalness )', 'vec3'), 'SpecularColor', 'color'));

        // NORMAL_VIEW

        var normalNode;

        if (material.normalNode && material.normalNode.isNode) {
          normalNode = material.normalNode;
        } else {
          normalNode = NormalNode(NormalNode.view);
        }

        addFlow('fragment', VarNode(normalNode, 'TransformedNormalView', 'vec3'));
      }

      // LIGHT

      var outputNode = diffuseColorNode;

      if (lightNode != null && lightNode is Node) {
        var lightContextNode = LightContextNode(lightNode);

        outputNode = addFlow('fragment', VarNode(lightContextNode, 'Light', 'vec3'));
      }

      // OUTGOING LIGHT

      var outgoingLightNode = nodeObject(outputNode).xyz;

      /// EMISSIVE

      var emissiveNode = material.emissiveNode;

      if (emissiveNode != null && emissiveNode.isNode) {
        outgoingLightNode = add(emissiveNode, outgoingLightNode);
      }

      outputNode = join([outgoingLightNode.xyz, nodeObject(diffuseColorNode).w]);

      var outputEncoding = renderer.outputEncoding;

      if (outputEncoding != LinearEncoding) {
        outputNode = ColorSpaceNode(ColorSpaceNode.linearToLinear, outputNode);
        outputNode.fromEncoding(outputEncoding);
      }

      addFlow('fragment', VarNode(outputNode, 'Output', 'vec4'));
    }
  }

  @override
  addFlowCode(code) {
    if (!RegExp(r";\s*$").hasMatch(code)) {
      code += ';';
    }

    super.addFlowCode(code + '\n\t');
  }

  @override
  getTexture(textureProperty, uvSnippet, [biasSnippet, shaderStage]) {
    shaderStage ??= this.shaderStage;

    if (shaderStage == 'fragment') {
      return """textureSample( $textureProperty, ${textureProperty}_sampler, $uvSnippet )""";
    } else {
      _include('repeatWrapping');

      var dimension = """textureDimensions( $textureProperty, 0 )""";

      return """textureLoad( $textureProperty, repeatWrapping( $uvSnippet, $dimension ), 0 )""";
    }
  }

  @override
  getPropertyName(node, [shaderStage]) {
    shaderStage = shaderStage ?? this.shaderStage;

    if (node is NodeVary) {
      if (shaderStage == 'vertex') {
        return "NodeVarys.${node.name}";
      }
    } else if (node is NodeUniform) {
      var name = node.name;
      var type = node.type;

      if (type == 'texture') {
        return name;
      } else if (type == 'buffer') {
        return "NodeBuffer.$name";
      } else {
        return "NodeUniforms.$name";
      }
    }

    return super.getPropertyName(node);
  }

  getBindings() {
    var bindings = this.bindings;

    return [...bindings["vertex"], ...bindings["fragment"]];
  }

  @override
  getUniformFromNode(node, shaderStage, type) {
    var uniformNode = super.getUniformFromNode(node, shaderStage, type);
    Map nodeData = getDataFromNode(node, shaderStage);

    if (nodeData["uniformGPU"] == undefined) {
      var uniformGPU;

      var bindings = this.bindings[shaderStage];

      if (type == 'texture') {
        var sampler = WebGPUNodeSampler("${uniformNode.name}_sampler", uniformNode.node);
        var texture = WebGPUNodeSampledTexture(uniformNode.name, uniformNode.node);

        // add first textures in sequence and group for last
        var lastBinding = bindings[bindings.length - 1];
        var index = lastBinding && lastBinding.isUniformsGroup ? bindings.length - 1 : bindings.length;

        if (shaderStage == 'fragment') {
          bindings.splice(index, 0, sampler, texture);

          uniformGPU = [sampler, texture];
        } else {
          bindings.splice(index, 0, texture);

          uniformGPU = [texture];
        }
      } else if (type == 'buffer') {
        var buffer = WebGPUUniformBuffer('NodeBuffer', node.value);

        // add first textures in sequence and group for last
        var lastBinding = bindings[bindings.length - 1];
        var index = lastBinding && lastBinding.isUniformsGroup ? bindings.length - 1 : bindings.length;

        bindings.splice(index, 0, buffer);

        uniformGPU = buffer;
      } else {
        var uniformsGroup = this.uniformsGroup[shaderStage];

        if (uniformsGroup == undefined) {
          uniformsGroup = WebGPUNodeUniformsGroup(shaderStage);

          this.uniformsGroup[shaderStage] = uniformsGroup;

          bindings.add(uniformsGroup);
        }

        if (node is ArrayInputNode) {
          uniformGPU = [];

          for (var inputNode in node.nodes) {
            var uniformNodeGPU = _getNodeUniform(inputNode, type);

            // fit bounds to buffer
            uniformNodeGPU.boundary = getVectorLength(uniformNodeGPU.itemSize);
            uniformNodeGPU.itemSize = getStrideLength(uniformNodeGPU.itemSize);

            uniformsGroup.addUniform(uniformNodeGPU);

            uniformGPU.add(uniformNodeGPU);
          }
        } else {
          uniformGPU = _getNodeUniform(uniformNode, type);

          uniformsGroup.addUniform(uniformGPU);
        }
      }

      nodeData["uniformGPU"] = uniformGPU;

      if (shaderStage == 'vertex') {
        bindingsOffset['fragment'] = bindings.length;
      }
    }

    return uniformNode;
  }

  @override
  getAttributes(shaderStage) {
    var snippets = [];

    if (shaderStage == 'vertex') {
      var attributes = this.attributes;
      var length = attributes.length;

      for (var index = 0; index < length; index++) {
        var attribute = attributes[index];
        var name = attribute.name;
        var type = getType(attribute.type);

        snippets.add("@location( $index ) $name  : $type ");
      }
    }

    return snippets.join(',\n\t');
  }

  @override
  getVars(shaderStage) {
    var snippets = [];

    var vars = this.vars[shaderStage];

    for (var index = 0; index < vars.length; index++) {
      var variable = vars[index];

      var name = variable.name;
      var type = getType(variable.type);

      snippets.add("\tvar $name : $type;");
    }

    return "\n${snippets.join('\n')}\n";
  }

  @override
  getVarys(shaderStage) {
    var snippets = [];

    if (shaderStage == 'vertex') {
      snippets.add('@builtin( position ) Vertex: vec4<f32>');

      var varys = this.varys;

      for (var index = 0; index < varys.length; index++) {
        var vary = varys[index];

        snippets.add(" @location( $index ) ${vary.name} : ${getType(vary.type)}");
      }
    } else if (shaderStage == 'fragment') {
      var varys = this.varys;

      for (var index = 0; index < varys.length; index++) {
        var vary = varys[index];

        snippets.add("@location( $index ) ${vary.name} : ${getType(vary.type)}");
      }
    }

    var code = snippets.join(',\n\t');

    return shaderStage == 'vertex' ? _getWGSLStruct('NodeVarysStruct', code) : code;
  }

  @override
  getUniforms(shaderStage) {
    var uniforms = this.uniforms[shaderStage];

    var bindingSnippets = [];
    var bufferSnippets = [];
    var groupSnippets = [];

    var index = bindingsOffset[shaderStage];

    for (var uniform in uniforms) {
      if (uniform.type == 'texture') {
        if (shaderStage == 'fragment') {
          bindingSnippets.add("@group( 0 ) @binding( ${index++} ) var ${uniform.name}_sampler : sampler;");
        }

        bindingSnippets.add("@group( 0 ) @binding( ${index++} ) var ${uniform.name} : texture_2d<f32>;");
      } else if (uniform.type == 'cubeTexture') {
        if (shaderStage == 'fragment') {
          bindingSnippets.add("@group( 0 ) @binding( ${index++} ) var ${uniform.name}_sampler : sampler;");
        }

        bindingSnippets.add("@group( 0 ) @binding( ${index++} ) var ${uniform.name} : texture_cube<f32>;");
      } else if (uniform.type == 'buffer') {
        var bufferNode = uniform.node;
        var bufferType = getType(bufferNode.bufferType);
        var bufferCount = bufferNode.bufferCount;

        var bufferSnippet = "\t${uniform.name} : array< $bufferType, $bufferCount >\n";

        bufferSnippets.add(_getWGSLUniforms('NodeBuffer', bufferSnippet, index++));
      } else {
        var vectorType = getType(getVectorType(uniform.type));

        if (uniform.value is List) {
          var length = uniform.value.length;

          groupSnippets.add("uniform $vectorType[ $length ] ${uniform.name}");
        } else {
          groupSnippets.add("\t${uniform.name} : $vectorType");
        }
      }
    }

    var code = bindingSnippets.join('\n');
    code += bufferSnippets.join(',\n');

    if (groupSnippets.isNotEmpty) {
      code += _getWGSLUniforms('NodeUniforms', groupSnippets.join(',\n'), index++);
    }

    return code;
  }

  @override
  buildCode() {
    var shadersData = {"fragment": {}, "vertex": {}};

    for (var shaderStage in shadersData.keys) {
      var flow = '// code\n';
      flow += "\t${flowCode[shaderStage]}";
      flow += '\n';

      var flowNodes = this.flowNodes[shaderStage];

      var mainNode;
      if (flowNodes.length >= 1) {
        mainNode = flowNodes[flowNodes.length - 1];
      }

      for (var node in flowNodes) {
        Map flowSlotData = getFlowData(shaderStage, node);
        var slotName = node.name;

        if (slotName != null) {
          if (flow.isNotEmpty) flow += '\n';

          flow += "\t// FLOW -> $slotName\n\t";
        }

        flow += "${flowSlotData["code"]}\n\t";

        if (node == mainNode) {
          flow += '// FLOW RESULT\n\t';

          if (shaderStage == 'vertex') {
            flow += 'NodeVarys.Vertex = ';
          } else if (shaderStage == 'fragment') {
            flow += 'return ';
          }

          flow += "${flowSlotData["result"]};";
        }
      }

      var stageData = shadersData[shaderStage]!;

      stageData["uniforms"] = getUniforms(shaderStage);
      stageData["attributes"] = getAttributes(shaderStage);
      stageData["varys"] = getVarys(shaderStage);
      stageData["vars"] = getVars(shaderStage);
      stageData["codes"] = getCodes(shaderStage);
      stageData["flow"] = flow;
    }

    vertexShader = _getWGSLVertexCode(shadersData["vertex"]);
    fragmentShader = _getWGSLFragmentCode(shadersData["fragment"]);
  }

  @override
  getMethod(method) {
    if (wgslPolyfill[method] != undefined) {
      _include(method);
    }

    return wgslMethods[method] ?? method;
  }

  @override
  getType(type) {
    return wgslTypeLib[type] ?? type;
  }

  _include(name) {
    wgslPolyfill[name]!.build(this);
  }

  _getNodeUniform(uniformNode, type) {
    if (type == 'float') return FloatNodeUniform(uniformNode);
    if (type == 'vec2') return Vector2NodeUniform(uniformNode);
    if (type == 'vec3') return Vector3NodeUniform(uniformNode);
    if (type == 'vec4') return Vector4NodeUniform(uniformNode);
    if (type == 'color') return ColorNodeUniform(uniformNode);
    if (type == 'mat3') return Matrix3NodeUniform(uniformNode);
    if (type == 'mat4') return Matrix4NodeUniform(uniformNode);

    throw ("Uniform $type not declared.");
  }

  _getWGSLVertexCode(shaderData) {
    return """${getSignature()}

// uniforms
${shaderData["uniforms"]}

// varys
${shaderData["varys"]}

// codes
${shaderData["codes"]}

[[ stage( vertex ) ]]
fn main( ${shaderData["attributes"]} ) -> NodeVarysStruct {

	// system
	var NodeVarys: NodeVarysStruct;

	// vars
	${shaderData["vars"]}

	// flow
	${shaderData["flow"]}

	return NodeVarys;

}
""";
  }

  _getWGSLFragmentCode(shaderData) {
    return """${getSignature()}

// uniforms
${shaderData["uniforms"]}

// codes
${shaderData["codes"]}

[[ stage( fragment ) ]]
fn main( ${shaderData["varys"]} ) -> [[ location( 0 ) ]] vec4<f32> {

	// vars
	${shaderData["vars"]}

	// flow
	${shaderData["flow"]}

}
""";
  }

  _getWGSLStruct(name, vars) {
    return """
struct $name {
$vars
};""";
  }

  _getWGSLUniforms(name, vars, [binding = 0, group = 0]) {
    var structName = name + 'Struct';
    var structSnippet = _getWGSLStruct(structName, vars);

    return """$structSnippet
[[ binding( $binding ), group( $group ) ]]
var<uniform> $name : $structName;""";
  }
}
