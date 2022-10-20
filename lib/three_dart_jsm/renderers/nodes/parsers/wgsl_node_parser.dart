import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class WGSLNodeParser extends NodeParser {
  @override
  parseFunction(source) {
    return WGSLNodeFunction(source);
  }
}
