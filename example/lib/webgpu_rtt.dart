import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';

import 'package:three_dart/three_dart.dart' as THREE;
import 'package:three_dart_jsm/three_dart_jsm.dart' as THREE_JSM;

class webgpu_rtt extends StatefulWidget {
  String fileName;
  webgpu_rtt({Key? key, required this.fileName}) : super(key: key);

  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgpu_rtt> {
  THREE_JSM.WebGPURenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late THREE.Scene scene;
  late THREE.Camera camera;
  late THREE.Mesh mesh;

  num dpr = 1.0;

  ui.Image? img;


  bool verbose = true;
  bool disposed = false;

  bool loaded = false;

  late THREE.Object3D box;

  late THREE.Texture texture;

  late THREE.WebGLRenderTarget renderTarget;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // width = screenSize!.width / 10;
    // height = width;

    width = 256.0;
    height = 256.0;

    init();
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return SingleChildScrollView(child: _build(context));
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          clickRender();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Column(
      children: [
        Container(
          child: Stack(
            children: [
              Container(
                color: Colors.black,
                width: width.toDouble(),
                height: height.toDouble(),
                child: RawImage(image: img),
              )
            ],
          ),
        ),
      ],
    );
  }

  init() {
    camera = new THREE.PerspectiveCamera( 70, width / height, 0.1, 100 );
    camera.position.z = 40;

    scene = new THREE.Scene();
    scene.background = new THREE.Color( 0x0000ff );

    // textured mesh

    var geometryBox = new THREE.BoxGeometry(10, 10, 10);
    var materialBox = new THREE_JSM.MeshBasicNodeMaterial(null);
    materialBox.colorNode = new THREE_JSM.ColorNode( new THREE.Color(1.0, 1.0, 0.0) );

    box = new THREE.Mesh( geometryBox, materialBox );

    box.rotation.set(0.1, 0.5, 1.2);

    scene.add( box );

    camera.lookAt(scene.position);

    renderer = new THREE_JSM.WebGPURenderer({
      "width": width.toInt(),
      "height": height.toInt(),
      "antialias": false,
      "sampleCount": 1
    });
    dpr = 1.0;
    renderer!.setPixelRatio( dpr );
    renderer!.setSize( width.toInt(), height.toInt() );
    renderer!.init();

    var pars = THREE.WebGLRenderTargetOptions({"format": THREE.RGBAFormat, "samples": 1});
    renderTarget = THREE.WebGLRenderTarget(
        (width * dpr).toInt(), (height * dpr).toInt(), pars);
    renderer!.setRenderTarget(renderTarget);
    // sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget);
  }

  animate() {
    box.rotation.x += 0.01;
    box.rotation.y += 0.02;
    box.rotation.z += 0.04;

    renderer!.render( scene, camera );

    var pixels = renderer!.getPixels();

    var target = THREE.Vector2();
    renderer!.getSize(target);

    // print(" -----------target: ${target.x} ${target.y}----------- pixels: ${pixels} ");

    if (pixels != null) {
      ui.decodeImageFromPixels(pixels!, target.x.toInt(), target.y.toInt(), ui.PixelFormat.rgba8888,
          (image) {
        setState(() {
          img = image;
        });
      });
    }

    // Future.delayed(const Duration(milliseconds: 33), () {
    //   animate();
    // });
  }

  clickRender() {
    print(" click render .... ");
    animate();
  }

  @override
  void dispose() {
    print(" dispose ............. ");
    disposed = true;

    super.dispose();
  }
}
