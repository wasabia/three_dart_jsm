// /// Reference: https://en.wikipedia.org/wiki/Cel_shading
// ///
// /// API
// ///
// /// 1. Traditional
// ///
// /// const effect = new OutlineEffect( renderer );
// ///
// /// function render() {
// ///
// /// 	effect.render( scene, camera );
// ///
// /// }
// ///
// /// 2. VR compatible
// ///
// /// const effect = new OutlineEffect( renderer );
// /// let renderingOutline = false;
// ///
// /// scene.onAfterRender = function () {
// ///
// /// 	if ( renderingOutline ) return;
// ///
// /// 	renderingOutline = true;
// ///
// /// 	effect.renderOutline( scene, camera );
// ///
// /// 	renderingOutline = false;
// ///
// /// };
// ///
// /// function render() {
// ///
// /// 	renderer.render( scene, camera );
// ///
// /// }
// ///
// /// // How to set default outline parameters
// /// new OutlineEffect( renderer, {
// /// 	defaultThickness: 0.01,
// /// 	defaultColor: [ 0, 0, 0 ],
// /// 	defaultAlpha: 0.8,
// /// 	defaultKeepAlive: true // keeps outline material in cache even if material is removed from scene
// /// } );
// ///
// /// // How to set outline parameters for each material
// /// material.userData.outlineParameters = {
// /// 	thickness: 0.01,
// /// 	color: [ 0, 0, 0 ],
// /// 	alpha: 0.8,
// /// 	visible: true,
// /// 	keepAlive: true
// /// };
// import 'package:three_dart/three3d/constants.dart';
// import 'package:three_dart/three3d/materials/shader_material.dart';
// import 'package:three_dart/three3d/math/color.dart';
// import 'package:three_dart/three3d/renderers/shaders/uniforms_utils.dart';
// import 'package:three_dart/three_dart.dart' as three;
//
// class OutlineEffect {
//   final three.WebGLRenderer renderer;
//   final Map<String, dynamic> parameters;
//   late bool enabled;
//   late Color defaultThickness;
//   late Color defaultColor;
//   late int defaultAlpha;
//   late bool defaultKeepAlive;
//   late Map<String, dynamic> cache;
//   late int removeThresholdCount;
//   late Map<String, dynamic> originalMaterials;
//   late Map<String, dynamic> originalOnBeforeRenders;
//   late Map<String, dynamic> uniformsOutline;
//   late dynamic fragmentShader;
//   late dynamic vertexShader;
//
//   OutlineEffect(this.renderer, this.parameters) {
//     enabled = true;
//
//     defaultThickness = parameters['defaultThickness'] ?? 0.003;
//     defaultColor = Color().fromArray(parameters['defaultColor'] ?? [ 0, 0, 0]);
//     defaultAlpha = parameters['defaultAlpha'] ?? 1.0;
//     defaultKeepAlive = parameters['defaultKeepAlive'] ?? false;
//
//     // object.material.uuid -> outlineMaterial or
//     // object.material[ n ].uuid -> outlineMaterial
//     // save at the outline material creation and release
//     // if it's unused removeThresholdCount frames
//     // unless keepAlive is true.
//     cache = {};
//
//     removeThresholdCount = 60;
//
//     // outlineMaterial.uuid -> object.material or
//     // outlineMaterial.uuid -> object.material[ n ]
//     // save before render and release after render.
//     originalMaterials = {};
//
//     // object.uuid -> originalOnBeforeRender
//     // save before render and release after render.
//     originalOnBeforeRenders = {};
//
//     //this.cache = cache;  // for debug
//
//     uniformsOutline = {
//       "outlineThickness": { "value": defaultThickness},
//       "outlineColor": { "value": defaultColor},
//       "outlineAlpha": { "value": defaultAlpha}
//     };
//
//     vertexShader = [
//       '#include <common>',
//       '#include <uv_pars_vertex>',
//       '#include <displacementmap_pars_vertex>',
//       '#include <fog_pars_vertex>',
//       '#include <morphtarget_pars_vertex>',
//       '#include <skinning_pars_vertex>',
//       '#include <logdepthbuf_pars_vertex>',
//       '#include <clipping_planes_pars_vertex>',
//
//       'uniform float outlineThickness;',
//
//       'vec4 calculateOutline( vec4 pos, vec3 normal, vec4 skinned ) {',
//       '	float thickness = outlineThickness;',
//       '	const float ratio = 1.0;',
//       // TODO: support outline thickness ratio for each vertex
//       '	vec4 pos2 = projectionMatrix * modelViewMatrix * vec4( skinned.xyz + normal, 1.0 );',
//       // NOTE: subtract pos2 from pos because BackSide objectNormal is negative
//       '	vec4 norm = normalize( pos - pos2 );',
//       '	return pos + norm * thickness * pos.w * ratio;',
//       '}',
//
//       'void main() {',
//
//       '	#include <uv_vertex>',
//
//       '	#include <beginnormal_vertex>',
//       '	#include <morphnormal_vertex>',
//       '	#include <skinbase_vertex>',
//       '	#include <skinnormal_vertex>',
//
//       '	#include <begin_vertex>',
//       '	#include <morphtarget_vertex>',
//       '	#include <skinning_vertex>',
//       '	#include <displacementmap_vertex>',
//       '	#include <project_vertex>',
//
//       '	vec3 outlineNormal = - objectNormal;',
//       // the outline material is always rendered with BackSide
//
//       '	gl_Position = calculateOutline( gl_Position, outlineNormal, vec4( transformed, 1.0 ) );',
//
//       '	#include <logdepthbuf_vertex>',
//       '	#include <clipping_planes_vertex>',
//       '	#include <fog_vertex>',
//
//       '}',
//
//     ].join('\n');
//
//     fragmentShader = [
//
//       '#include <common>',
//       '#include <fog_pars_fragment>',
//       '#include <logdepthbuf_pars_fragment>',
//       '#include <clipping_planes_pars_fragment>',
//
//       'uniform vec3 outlineColor;',
//       'uniform float outlineAlpha;',
//
//       'void main() {',
//
//       '	#include <clipping_planes_fragment>',
//       '	#include <logdepthbuf_fragment>',
//
//       '	gl_FragColor = vec4( outlineColor, outlineAlpha );',
//
//       '	#include <tonemapping_fragment>',
//       '	#include <encodings_fragment>',
//       '	#include <fog_fragment>',
//       '	#include <premultiplied_alpha_fragment>',
//
//       '}'
//
//     ].join('\n');
//   }
//
//   ShaderMaterial createMaterial() {
//     return ShaderMaterial({
//       "type": 'OutlineEffect',
//       "uniforms": UniformsUtils.merge([
//         UniformsLib[ 'fog' ],
//         UniformsLib[ 'displacementmap' ],
//         uniformsOutline
//       ]),
//       vertexShader: vertexShader,
//       fragmentShader: fragmentShader,
//       "side": BackSide
//     });
//   }
//
//   dynamic getOutlineMaterialFromCache(originalMaterial) {
//     var data = cache[ originalMaterial.uuid ];
//
//     if (data == null) {
//       data = {
//         "material": createMaterial(),
//         "used": true,
//         "keepAlive"": defaultKeepAlive",
//         "count": 0
//       };
//
//       cache[ originalMaterial.uuid ] = data;
//     }
//
//     data.used = true;
//
//     return data.material;
//   }
//
//   dynamic getOutlineMaterial(originalMaterial) {
//     var outlineMaterial = getOutlineMaterialFromCache(originalMaterial);
//
//     originalMaterials[ outlineMaterial.uuid ] = originalMaterial;
//
//     updateOutlineMaterial(outlineMaterial, originalMaterial);
//
//     return outlineMaterial;
//   }
//
//   bool isCompatible(dynamic object) {
//     var geometry = object.geometry;
//     var hasNormals = (geometry != null) && (geometry.attributes.normal != null);
//
//     return (object.isMesh == true && object.material != null &&
//         hasNormals == true);
//   }
//
//   void setOutlineMaterial(object) {
//     if (isCompatible(object) == false) return;
//
//     if (Array.isArray(object.material)) {
//       for (var i = 0, il = object.material.length; i < il; i ++) {
//         object.material[ i ] = getOutlineMaterial(object.material[ i ]);
//       }
//     } else {
//       object.material = getOutlineMaterial(object.material);
//     }
//
//     originalOnBeforeRenders[ object.uuid ] = object.onBeforeRender;
//     object.onBeforeRender = onBeforeRender;
//   }
//
//   void restoreOriginalMaterial(object) {
//     if (isCompatible(object) == false) return;
//
//     if (Array.isArray(object.material)) {
//       for (var i = 0, il = object.material.length; i < il; i ++) {
//         object.material[ i ] = originalMaterials[ object.material[ i ].uuid ];
//       }
//     } else {
//       object.material = originalMaterials[ object.material.uuid ];
//     }
//
//     object.onBeforeRender = originalOnBeforeRenders[ object.uuid ];
//   }
//
//   void onBeforeRender(renderer, scene, camera, geometry, material) {
//     var originalMaterial = originalMaterials[ material.uuid ];
//
//     // just in case
//     if (originalMaterial == null) return;
//
//     updateUniforms(material, originalMaterial);
//   }
//
//   void updateUniforms(material, originalMaterial) {
//     var outlineParameters = originalMaterial.userData.outlineParameters;
//
//     material.uniforms.outlineAlpha.value = originalMaterial.opacity;
//
//     if (outlineParameters != null) {
//       if (outlineParameters.thickness != null)
//         material.uniforms.outlineThickness.value = outlineParameters.thickness;
//       if (outlineParameters.color != null) material.uniforms.outlineColor.value
//           .fromArray(outlineParameters.color);
//       if (outlineParameters.alpha != null)
//         material.uniforms.outlineAlpha.value = outlineParameters.alpha;
//     }
//
//     if (originalMaterial.displacementMap) {
//       material.uniforms.displacementMap.value =
//           originalMaterial.displacementMap;
//       material.uniforms.displacementScale.value =
//           originalMaterial.displacementScale;
//       material.uniforms.displacementBias.value =
//           originalMaterial.displacementBias;
//     }
//   }
//
//   void updateOutlineMaterial(material, originalMaterial) {
//     if (material.name == 'invisible') return;
//
//     var outlineParameters = originalMaterial.userData.outlineParameters;
//
//     material.fog = originalMaterial.fog;
//     material.toneMapped = originalMaterial.toneMapped;
//     material.premultipliedAlpha = originalMaterial.premultipliedAlpha;
//     material.displacementMap = originalMaterial.displacementMap;
//
//     if (outlineParameters != null) {
//       if (originalMaterial.visible == false) {
//         material.visible = false;
//       } else {
//         material.visible =
//         (outlineParameters.visible != null) ? outlineParameters.visible : true;
//       }
//
//       material.transparent =
//       (outlineParameters.alpha != null && outlineParameters.alpha < 1.0)
//           ? true
//           : originalMaterial.transparent;
//
//       if (outlineParameters.keepAlive != null)
//         cache[ originalMaterial.uuid ].keepAlive = outlineParameters.keepAlive;
//     } else {
//       material.transparent = originalMaterial.transparent;
//       material.visible = originalMaterial.visible;
//     }
//
//     if (originalMaterial
//         .wireframe === true || originalMaterial.depthTest === false)
//       material.visible = false;
//
//     if (originalMaterial.clippingPlanes) {
//       material.clipping = true;
//
//       material.clippingPlanes = originalMaterial.clippingPlanes;
//       material.clipIntersection = originalMaterial.clipIntersection;
//       material.clipShadows = originalMaterial.clipShadows;
//     }
//
//     material.version =
//         originalMaterial.version; // update outline material if necessary
//
//   }
//
//   void cleanupCache() {
//     var keys;
//
//     // clear originialMaterials
//     keys = Object.keys(originalMaterials);
//
//     for (var i = 0, il = keys.length; i < il; i ++) {
//       originalMaterials[ keys[ i ] ] = null;
//     }
//
//     // clear originalOnBeforeRenders
//     keys = Object.keys(originalOnBeforeRenders);
//
//     for (let i = 0, il = keys.length; i < il; i ++) {
//       originalOnBeforeRenders[ keys[ i ] ] = null;
//     }
//
//     // remove unused outlineMaterial from cache
//     keys = Object.keys(cache);
//
//     for (var i = 0, il = keys.length; i < il; i ++) {
//       const key = keys[ i ];
//
//       if (cache[ key ].used == false) {
//         cache[ key ].count ++;
//
//         if (cache[ key ].keepAlive == false &&
//             cache[ key ].count > removeThresholdCount) {
//           delete cache[ key];
//         }
//       } else {
//         cache[ key ].used = false;
//         cache[ key ].count = 0;
//       }
//     }
//   }
//
//   void render(three.Scene scene, three.Camera camera) {
//     if (enabled == false) {
//       renderer.render(scene, camera);
//       return;
//     }
//     var currentAutoClear = renderer.autoClear;
//     renderer.autoClear = autoClear;
//
//     renderer.render(scene, camera);
//
//     renderer.autoClear = currentAutoClear;
//
//     renderOutline(scene, camera);
//   }
//
//
//   void renderOutline(scene, camera) {
//     var currentAutoClear = renderer.autoClear;
//     var currentSceneAutoUpdate = scene.matrixWorldAutoUpdate;
//     var currentSceneBackground = scene.background;
//     var currentShadowMapEnabled = renderer.shadowMap.enabled;
//
//     scene.matrixWorldAutoUpdate = false;
//     scene.background = null;
//     renderer.autoClear = false;
//     renderer.shadowMap.enabled = false;
//
//     scene.traverse(setOutlineMaterial);
//
//     renderer.render(scene, camera);
//
//     scene.traverse(restoreOriginalMaterial);
//
//     cleanupCache();
//
//     scene.matrixWorldAutoUpdate = currentSceneAutoUpdate;
//     scene.background = currentSceneBackground;
//     renderer.autoClear = currentAutoClear;
//     renderer.shadowMap.enabled = currentShadowMapEnabled;
//
//     /*
// 		 * See #9918
// 		 *
// 		 * The following property copies and wrapper methods enable
// 		 * OutlineEffect to be called from other *Effect, like
// 		 *
// 		 * effect = new StereoEffect( new OutlineEffect( renderer ) );
// 		 *
// 		 * function render () {
// 		 *
// 	 	 * 	effect.render( scene, camera );
// 		 *
// 		 * }
// 		 */
//     autoClear = renderer.autoClear;
//     domElement = renderer.domElement;
//     shadowMap = renderer.shadowMap;
//   }
//
//   void clear(color, depth, stencil) {
//     renderer.clear(color, depth, stencil);
//   }
//
//   double getPixelRatio() {
//     return renderer.getPixelRatio();
//   }
//
//   void setPixelRatio(double value) {
//     renderer.setPixelRatio(value);
//   }
//
//   three.Vector2 getSize(target) {
//     return renderer.getSize(target);
//   }
//
//   void setSize(width, height, bool updateStyle) {
//     renderer.setSize(width, height, updateStyle);
//   }
//
//   void setViewport(x, y, width, height) {
//     renderer.setViewport(x, y, width, height);
//   }
//
//   void setScissor(x, y, width, height) {
//     renderer.setScissor(x, y, width, height);
//   }
//
//   void setSciissorTest(bool boolean) {
//     renderer.setScissorTest(boolean);
//   }
//
//   void setRenderTarget(renderTarget) {
//     renderer.setRenderTarget(renderTarget);
//   }
//
// }
