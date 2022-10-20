import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class LightContextNode extends ContextNode {
  LightContextNode(node) : super(node);

  @override
  getNodeType([builder, output]) {
    return 'vec3';
  }

  @override
  generate([builder, output]) {
    var material = builder.material;

    var lightingModel;

    if (material.isMeshStandardMaterial == true) {
      lightingModel = PhysicalLightingModel;
    }

    var directDiffuse = VarNode(Vector3Node(), 'DirectDiffuse', 'vec3');
    var directSpecular = VarNode(Vector3Node(), 'DirectSpecular', 'vec3');

    context.directDiffuse = directDiffuse;
    context.directSpecular = directSpecular;

    if (lightingModel != null) {
      context.lightingModel = lightingModel;
    }

    // add code

    var type = getNodeType(builder);

    super.generate(builder, type);

    var totalLight = OperatorNode('+', directDiffuse, directSpecular);

    return totalLight.build(builder, type);
  }
}
