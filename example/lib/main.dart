import 'package:example/ExampleApp.dart';
import 'package:example/webgpu_rtt.dart';
import 'package:flutter/material.dart';

void main() {
  // runApp(ExampleApp());
  runApp(MaterialApp(home: webgpu_rtt(fileName: 'webgpu_rtt'),));
}
