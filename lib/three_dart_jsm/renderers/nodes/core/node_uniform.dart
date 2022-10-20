class NodeUniform {
  late String name;
  late String type;
  late dynamic node;
  late dynamic needsUpdate;

  NodeUniform(name, type, node, [needsUpdate]) {
    this.name = name;
    this.type = type;
    this.node = node;
    this.needsUpdate = needsUpdate;
  }

  get value {
    return node.value;
  }

  set value(val) {
    node.value = val;
  }
}
