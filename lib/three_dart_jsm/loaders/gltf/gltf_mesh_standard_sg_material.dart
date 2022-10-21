import 'package:three_dart/three_dart.dart';

/// Specular-Glossiness Extension
///
/// Specification: https://github.com/KhronosGroup/glTF/tree/master/extensions/2.0/Khronos/KHR_materials_pbrSpecularGlossiness

/// A sub class of StandardMaterial with some of the functionality
/// changed via the `onBeforeCompile` callback
/// @pailhead

class GLTFMeshStandardSGMaterial extends MeshStandardMaterial {
  bool isGLTFSpecularGlossinessMaterial = true;

  GLTFMeshStandardSGMaterial(params) : super(params) {
    type = "GLTFSpecularGlossinessMaterial";
    //various chunks that need replacing
    var specularMapParsFragmentChunk =
        ['#ifdef USE_SPECULARMAP', '	uniform sampler2D specularMap;', '#endif'].join('\n');

    var glossinessMapParsFragmentChunk =
        ['#ifdef USE_GLOSSINESSMAP', '	uniform sampler2D glossinessMap;', '#endif'].join('\n');

    var specularMapFragmentChunk = [
      'vec3 specularFactor = specular;',
      '#ifdef USE_SPECULARMAP',
      '	vec4 texelSpecular = texture2D( specularMap, vUv );',
      '	// reads channel RGB, compatible with a glTF Specular-Glossiness (RGBA) texture',
      '	specularFactor *= texelSpecular.rgb;',
      '#endif'
    ].join('\n');

    var glossinessMapFragmentChunk = [
      'float glossinessFactor = glossiness;',
      '#ifdef USE_GLOSSINESSMAP',
      '	vec4 texelGlossiness = texture2D( glossinessMap, vUv );',
      '	// reads channel A, compatible with a glTF Specular-Glossiness (RGBA) texture',
      '	glossinessFactor *= texelGlossiness.a;',
      '#endif'
    ].join('\n');

    var lightPhysicalFragmentChunk = [
      'PhysicalMaterial material;',
      'material.diffuseColor = diffuseColor.rgb * ( 1. - max( specularFactor.r, max( specularFactor.g, specularFactor.b ) ) );',
      'vec3 dxy = max( abs( dFdx( geometryNormal ) ), abs( dFdy( geometryNormal ) ) );',
      'float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );',
      'material.specularRoughness = max( 1.0 - glossinessFactor, 0.0525 ); // 0.0525 corresponds to the base mip of a 256 cubemap.',
      'material.specularRoughness += geometryRoughness;',
      'material.specularRoughness = min( material.specularRoughness, 1.0 );',
      'material.specularColor = specularFactor;',
    ].join('\n');

    uniforms = {
      "specular": {"value": Color.fromHex(0xffffff)},
      "glossiness": {"value": 1},
      "specularMap": {"value": null},
      "glossinessMap": {"value": null}
    };

    onBeforeCompile = (shader) {
      uniforms.forEach((uniformName, _) {
        shader.uniforms[uniformName] = uniforms[uniformName];
      });

      shader.fragmentShader = shader.fragmentShader
          .replace('uniform float roughness;', 'uniform vec3 specular;')
          .replace('uniform float metalness;', 'uniform float glossiness;')
          .replace('#include <roughnessmap_pars_fragment>', specularMapParsFragmentChunk)
          .replace('#include <metalnessmap_pars_fragment>', glossinessMapParsFragmentChunk)
          .replace('#include <roughnessmap_fragment>', specularMapFragmentChunk)
          .replace('#include <metalnessmap_fragment>', glossinessMapFragmentChunk)
          .replace('#include <lights_physical_fragment>', lightPhysicalFragmentChunk);
    };

    // delete this.metalness;
    // delete this.roughness;
    // delete this.metalnessMap;
    // delete this.roughnessMap;

    setValues(params);
  }

  @override
  get specular => uniforms["specular"]["value"];

  @override
  set specular(v) {
    uniforms["specular"]["value"] = v;
  }

  @override
  get specularMap => uniforms["specularMap"]["value"];
  @override
  set specularMap(v) {
    uniforms["specularMap"]["value"] = v;

    if (v != null) {
      defines!["USE_SPECULARMAP"] = ''; // USE_UV is set by the renderer for specular maps

    } else {
      // delete this.defines.USE_SPECULARMAP;
      defines!.remove("USE_SPECULARMAP");
    }
  }

  get glossiness => uniforms["glossiness"]["value"];

  set glossiness(v) {
    uniforms["glossiness"]["value"] = v;
  }

  get glossinessMap => uniforms["glossinessMap"]["value"];
  set glossinessMap(v) {
    uniforms["glossinessMap"]["value"] = v;

    if (v != null) {
      defines!["USE_GLOSSINESSMAP"] = '';
      defines!["USE_UV"] = '';
    } else {
      // delete this.defines.USE_GLOSSINESSMAP;
      // delete this.defines.USE_UV;
      defines!.remove("USE_GLOSSINESSMAP");
      defines!.remove("USE_UV");
    }
  }

  @override
  copy(Material source) {
    super.copy(source);

    var s = source as GLTFMeshStandardSGMaterial;

    specularMap = s.specularMap;
    specular!.copy(s.specular!);
    glossinessMap = s.glossinessMap;
    glossiness = s.glossiness;
    // delete this.metalness;
    // delete this.roughness;
    // delete this.metalnessMap;
    // delete this.roughnessMap;
    return this;
  }
}
