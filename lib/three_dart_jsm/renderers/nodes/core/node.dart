import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/extra/console.dart';
import 'package:three_dart_jsm/three_dart_jsm/renderers/nodes/index.dart';

class Node {
  late String uuid;
  String? nodeType;
  late NodeUpdateType updateType;
  late dynamic inputType;

  dynamic xyz;
  dynamic w;

  late bool constant;

  late int generateLength;

  dynamic value;

  Node([this.nodeType]) {
    updateType = NodeUpdateType.None;

    uuid = MathUtils.generateUUID();
  }

  get type {
    return runtimeType.toString();
  }

  getHash([builder]) {
    return uuid;
  }

  getUpdateType([builder]) {
    return updateType;
  }

  getNodeType([builder, output]) {
    return nodeType;
  }

  update([frame]) {
    console.warn('Abstract function.');
  }

  generate([builder, output]) {
    console.warn('Abstract function.');
  }

  build(NodeBuilder builder, [output]) {
    var hash = getHash(builder);
    var sharedNode = builder.getNodeFromHash(hash);

    if (sharedNode != undefined && this != sharedNode) {
      return sharedNode.build(builder, output);
    }

    builder.addNode(this);
    builder.addStack(this);

    // generate 函数的参数长度？
    // dart不支持
    var isGenerateOnce = (generateLength == 1);

    var snippet;

    if (isGenerateOnce) {
      var type = getNodeType(builder);
      var nodeData = builder.getDataFromNode(this);

      snippet = nodeData["snippet"];

      if (snippet == undefined) {
        snippet = generate(builder) ?? '';

        nodeData["snippet"] = snippet;
      }

      snippet = builder.format(snippet, type, output);
    } else {
      snippet = generate(builder, output) ?? '';
    }

    builder.removeStack(this);

    return snippet;
  }

  getProperty(String name) {
    if (name == "xyz") {
      return xyz;
    } else {
      throw ("Node ${this} getProperty name: $name is not support  ");
    }
  }
}
