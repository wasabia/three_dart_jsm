class NodeFunctionInput {
  late String type;
  late String name;
  late int count;
  late String qualifier;
  late bool isConst;

  NodeFunctionInput(type, name, [count, qualifier = '', isConst = false]) {
    this.type = type;
    this.name = name;
    this.count = count;
    this.qualifier = qualifier;
    this.isConst = isConst;
  }
}
