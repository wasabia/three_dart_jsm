class NodeKeywords {
  late List keywords;
  late List nodes;
  late Map keywordsCallback;

  NodeKeywords() {
    keywords = [];
    nodes = [];
    keywordsCallback = {};
  }

  getNode(name) {
    var node = nodes[name];

    if (node == null && keywordsCallback[name] != null) {
      node = keywordsCallback[name](name);

      nodes[name] = node;
    }

    return node;
  }

  addKeyword(name, callback) {
    keywords.add(name);
    keywordsCallback[name] = callback;

    return this;
  }

  parse(code) {
    var keywordNames = keywords;

    var regExp = RegExp(r"\\b${keywordNames.join( '\\b|\\b' )}\\b", caseSensitive: false);

    var codeKeywords = code.match(regExp);

    var keywordNodes = [];

    if (codeKeywords != null) {
      for (var keyword in codeKeywords) {
        var node = getNode(keyword);

        if (node != null && !keywordNodes.contains(node)) {
          keywordNodes.add(node);
        }
      }
    }

    return keywordNodes;
  }

  include(builder, code) {
    var keywordNodes = parse(code);

    for (var keywordNode in keywordNodes) {
      keywordNode.build(builder);
    }
  }
}
