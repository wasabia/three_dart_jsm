import 'package:three_dart/three3d/math/math.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class CodeNode extends Node {
  late String code;
  late bool useKeywords;
  late List _includes;

  CodeNode([code = '', nodeType = 'code']) : super(nodeType) {
    this.code = code;

    useKeywords = false;

    _includes = [];
  }

  setIncludes(includes) {
    _includes = includes;

    return this;
  }

  getIncludes(builder) {
    return _includes;
  }

  @override
  generate([builder, output]) {
    if (useKeywords == true) {
      var contextKeywords = builder.context.keywords;

      if (contextKeywords != null) {
        var nodeData = builder.getDataFromNode(this, builder.shaderStage);

        nodeData.keywords ??= [];

        if (nodeData.keywords.indexOf(contextKeywords) == -1) {
          contextKeywords.include(builder, code);

          nodeData.keywords.push(contextKeywords);
        }
      }
    }

    var includes = getIncludes(builder);

    for (var include in includes) {
      include.build(builder);
    }

    var nodeCode = builder.getCodeFromNode(this, getNodeType(builder));
    nodeCode.code = code;

    return nodeCode.code;
  }
}
