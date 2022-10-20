import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class MaterialReferenceNode extends ReferenceNode {
  late dynamic material;

  MaterialReferenceNode(property, inputType, [material]) : super(property, inputType, material) {
    generateLength = 1;
    this.material = material;
  }

  @override
  update([frame]) {
    object = material ?? frame.material;

    super.update(frame);
  }
}
