import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

var getGeometryRoughness = shaderNode(() {
  var dxy = max(abs(dFdx(normalGeometry)), abs(dFdy(normalGeometry)));
  var geometryRoughness = max(max(dxy.x, dxy.y), dxy.z);

  return geometryRoughness;
});

var getRoughness = shaderNode((inputs) {
  var roughness = inputs.roughness;

  var geometryRoughness = getGeometryRoughness();

  var roughnessFactor = max(roughness, 0.0525); // 0.0525 corresponds to the base mip of a 256 cubemap.
  roughnessFactor = add(roughnessFactor, geometryRoughness);
  roughnessFactor = min(roughnessFactor, 1.0);

  return roughnessFactor;
});
