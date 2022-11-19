import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class BufferNode extends InputNode {
  late dynamic bufferType;
  late int bufferCount;

  BufferNode(value, this.bufferType, [this.bufferCount = 0]) : super('buffer') {
    this.value = value;
  }

  @override
  getNodeType([builder, output]) => bufferType;
}
