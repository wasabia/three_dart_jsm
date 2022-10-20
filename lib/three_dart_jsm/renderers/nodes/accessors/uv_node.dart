import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class UVNode extends AttributeNode {
  late int index;

  UVNode([index = 0]) : super(null, 'vec2') {
    this.index = index;
  }

  @override
  getAttributeName(builder) {
    var index = this.index;

    return 'uv${(index > 0 ? index + 1 : '')}';
  }
}
