// import './webgpu_rtt.dart';
import 'package:example/webgl_loader_fbx.dart';
import 'package:flutter/material.dart';

import 'ExampleApp.dart';

void main() {
  // runApp(ExampleApp());
  runApp(MaterialApp(home: webgl_loader_fbx(fileName: 'webgl_loader_fbx'),));
}
