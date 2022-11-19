import 'package:three_dart_jsm/extra/console.dart';

class NodeFunction {
  late dynamic type;
  late dynamic inputs;
  late String name;
  late String presicion;

  NodeFunction(this.type, this.inputs, [this.name = '', this.presicion = '']);

  getCode(/*name = this.name*/) {
    console.warn('Abstract function.');
  }
}
