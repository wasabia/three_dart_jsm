class NodeUniform {
  String name;
  String type;
  dynamic node;
  dynamic needsUpdate;

  NodeUniform(this.name, this.type, this.node, [this.needsUpdate]);

  get value {
    return node.value;
  }

  set value(val) {
    node.value = val;
  }
}
