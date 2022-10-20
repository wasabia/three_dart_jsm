import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

var skinning = shaderNode((inputs, builder) {
  var position = inputs.position;
  var normal = inputs.normal;
  var index = inputs.index;
  var weight = inputs.weight;
  var bindMatrix = inputs.bindMatrix;
  var bindMatrixInverse = inputs.bindMatrixInverse;
  var boneMatrices = inputs.boneMatrices;

  var boneMatX = element(boneMatrices, index.x);
  var boneMatY = element(boneMatrices, index.y);
  var boneMatZ = element(boneMatrices, index.z);
  var boneMatW = element(boneMatrices, index.w);

  // POSITION

  var skinVertex = mul(bindMatrix, position);

  var skinned = add(mul(mul(boneMatX, skinVertex), weight.x), mul(mul(boneMatY, skinVertex), weight.y),
      mul(mul(boneMatZ, skinVertex), weight.z), mul(mul(boneMatW, skinVertex), weight.w));

  var skinPosition = mul(bindMatrixInverse, skinned).xyz;

  // NORMAL

  var skinMatrix =
      add(mul(weight.x, boneMatX), mul(weight.y, boneMatY), mul(weight.z, boneMatZ), mul(weight.w, boneMatW));

  skinMatrix = mul(mul(bindMatrixInverse, skinMatrix), bindMatrix);

  var skinNormal = transformDirection(skinMatrix, normal).xyz;

  // ASSIGNS

  assign(position, skinPosition).build(builder);
  assign(normal, skinNormal).build(builder);
});

class SkinningNode extends Node {
  late dynamic skinnedMesh;
  late dynamic skinIndexNode;
  late dynamic skinWeightNode;
  late dynamic bindMatrixNode;
  late dynamic bindMatrixInverseNode;
  late dynamic boneMatricesNode;

  SkinningNode(this.skinnedMesh) : super('void') {
    updateType = NodeUpdateType.object;

    skinIndexNode = AttributeNode('skinIndex', 'uvec4');
    skinWeightNode = AttributeNode('skinWeight', 'vec4');

    bindMatrixNode = Matrix4Node(skinnedMesh.bindMatrix);
    bindMatrixInverseNode = Matrix4Node(skinnedMesh.bindMatrixInverse);
    boneMatricesNode = BufferNode(skinnedMesh.skeleton.boneMatrices, 'mat4', skinnedMesh.skeleton.bones.length);
  }

  @override
  generate([builder, output]) {
    // inout nodes
    var position = PositionNode(PositionNode.local);
    var normal = NormalNode(NormalNode.local);

    var index = skinIndexNode;
    var weight = skinWeightNode;
    var bindMatrix = bindMatrixNode;
    var bindMatrixInverse = bindMatrixInverseNode;
    var boneMatrices = boneMatricesNode;

    skinning({position, normal, index, weight, bindMatrix, bindMatrixInverse, boneMatrices}, builder);
  }

  @override
  update([frame]) {
    skinnedMesh.skeleton.update();
  }
}
