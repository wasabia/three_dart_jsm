import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class BufferNode extends InputNode {
  late dynamic bufferType;
  late int bufferCount;

  BufferNode(value, bufferType, [bufferCount = 0]) : super('buffer') {
    this.value = value;
    this.bufferType = bufferType;
    this.bufferCount = bufferCount;
  }

  @override
  getNodeType([builder, output]) {
    return bufferType;
  }
}
