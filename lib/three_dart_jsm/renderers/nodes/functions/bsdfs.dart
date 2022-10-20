import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

var fSchlick = shaderNode((inputs) {
  var f0 = inputs.f0;
  var f90 = inputs.f90;
  var dotVH = inputs.dotVH;

  // Original approximation by Christophe Schlick '94
  // float fresnel = pow( 1.0 - dotVH, 5.0 );

  // Optimized variant (presented by Epic at SIGGRAPH '13)
  // https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
  var fresnel = exp2(mul(sub(mul(-5.55473, dotVH), 6.98316), dotVH));

  return add(mul(f0, sub(1.0, fresnel)), mul(f90, fresnel));
}); // validated

var brdfLambert = shaderNode((inputs) {
  return mul(reciprocalPi, inputs.diffuseColor); // punctual light
}); // validated

var getDistanceAttenuation = shaderNode((inputs) {
  var lightDistance = inputs.lightDistance;
  var cutoffDistance = inputs.cutoffDistance;
  var decayExponent = inputs.decayExponent;

  return cond([
    and(greaterThan(cutoffDistance, 0), greaterThan(decayExponent, 0)),
    pow(saturate(add(div(negate(lightDistance), cutoffDistance), 1.0)), decayExponent),
    1.0
  ]);
}); // validated

//
// STANDARD
//

// Moving Frostbite to Physically Based Rendering 3.0 - page 12, listing 2
// https://seblagarde.files.wordpress.com/2015/07/course_notes_moving_frostbite_to_pbr_v32.pdf
var vGGXSmithCorrelated = shaderNode((inputs) {
  var alpha = inputs.alpha;
  var dotNL = inputs.dotNL;
  var dotNV = inputs.dotNV;

  var a2 = pow2(alpha);

  var gv = mul(dotNL, sqrt(add(a2, mul(sub(1.0, a2), pow2(dotNV)))));
  var gl = mul(dotNV, sqrt(add(a2, mul(sub(1.0, a2), pow2(dotNL)))));

  return div(0.5, max(add(gv, gl), epsilon));
}); // validated

// Microfacet Models for Refraction through Rough Surfaces - equation (33)
// http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html
// alpha is "roughness squared" in Disney’s reparameterization
var dGGX = shaderNode((inputs) {
  var alpha = inputs.alpha;
  var dotNH = inputs.dotNH;

  var a2 = pow2(alpha);

  var denom = add(mul(pow2(dotNH), sub(a2, 1.0)), 1.0); // avoid alpha = 0 with dotNH = 1

  return mul(reciprocalPi, div(a2, pow2(denom)));
}); // validated

// GGX Distribution, Schlick Fresnel, GGX_SmithCorrelated Visibility
var brdfGGX = shaderNode((inputs) {
  var lightDirection = inputs.lightDirection;
  var f0 = inputs.f0;
  var f90 = inputs.f90;
  var roughness = inputs.roughness;

  var alpha = pow2(roughness); // UE4's roughness

  var halfDir = normalize(add(lightDirection, positionViewDirection));

  var dotNL = saturate(dot(transformedNormalView, lightDirection));
  var dotNV = saturate(dot(transformedNormalView, positionViewDirection));
  var dotNH = saturate(dot(transformedNormalView, halfDir));
  var dotVH = saturate(dot(positionViewDirection, halfDir));

  var F = fSchlick({f0, f90, dotVH});

  var V = vGGXSmithCorrelated({alpha, dotNL, dotNV});

  var D = dGGX({alpha, dotNH});

  return mul(F, mul(V, D));
}); // validated

var reDirectPhysical = shaderNode((inputs) {
  var lightDirection = inputs.lightDirection;
  var lightColor = inputs.lightColor;
  var directDiffuse = inputs.directDiffuse;
  var directSpecular = inputs.directSpecular;

  var dotNL = saturate(dot(transformedNormalView, lightDirection));
  var irradiance = mul(dotNL, lightColor);

  irradiance = mul(irradiance, pi); // punctual light

  addTo(directDiffuse, mul(irradiance, brdfLambert({diffuseColor})));

  addTo(
      directSpecular,
      mul(irradiance,
          brdfGGX({"lightDirection": lightDirection, "f0": specularColor, "f90": 1, "roughness": roughness})));
});

var physicalLightingModel = shaderNode((inputs /*, builder*/) {
  // PHYSICALLY_CORRECT_LIGHTS <-> builder.renderer.physicallyCorrectLights === true

  reDirectPhysical(inputs);
});
