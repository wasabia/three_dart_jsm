class NodeFunctionInput {
  String type;
  String name;
  int count;
  String qualifier;
  bool isConst;

  NodeFunctionInput(
    this.type,
    this.name, [
    this.count = 1,
    this.qualifier = '',
    this.isConst = false,
  ]);
}
