import 'dart:ffi';
import 'dart:io';

import 'package:three_dart/three_dart.dart';
import 'package:three_dart_jsm/three_dart_jsm/loaders/darco/index.dart';

class DRACOLoaderPlatform extends Loader with DRACOLoader {
  final DynamicLibrary libEGL = Platform.isAndroid
      ? DynamicLibrary.open("libdraco.a")
      : DynamicLibrary.process();

  DRACOLoaderPlatform(manager) : super(manager) {}
}
