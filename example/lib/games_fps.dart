import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'package:three_dart/three_dart.dart' hide Texture, Color;
import 'package:three_dart_jsm/three_dart_jsm.dart';

class SphereData{
  SphereData({
    required this.mesh,
    required this.collider,
    required this.velocity
  });

  Mesh mesh;
  Sphere collider;
  Vector3 velocity;
}

class TestGame extends StatefulWidget {
  const TestGame({
    Key? key,
    required this.fileName
  }) : super(key: key);

  final String fileName;

  @override
  _TestGamePageState createState() => _TestGamePageState();
}

class _TestGamePageState extends State<TestGame> {
  FocusNode node = FocusNode();
  // gl values
  //late Object3D object;
  bool animationReady = false;
  late FlutterGlPlugin three3dRender;
  WebGLRenderTarget? renderTarget;
  WebGLRenderer? renderer;
  int? fboId;
  late double width;
  late double height;
  Size? screenSize;
  late Scene scene;
  late Camera camera;
  double dpr = 1.0;
  bool verbose = false;
  bool disposed = false;
  final GlobalKey<DomLikeListenableState> _globalKey = GlobalKey<DomLikeListenableState>();
  dynamic sourceTexture;

  int stepsPerFrame = 5;
  Clock clock = Clock();

  double gravity = 30;

  List<SphereData> spheres = [];
  int sphereIdx = 0;

  Octree worldOctree = Octree();
  Capsule playerCollider = Capsule(Vector3( 0, 0.35, 0 ), Vector3( 0, 1, 0 ), 0.35);

  Vector3 playerVelocity = Vector3();
  Vector3 playerDirection = Vector3();

  bool playerOnFloor = false;
  int mouseTime = 0;
  Map<LogicalKeyboardKey,bool> keyStates = {
    LogicalKeyboardKey.keyW: false,
    LogicalKeyboardKey.keyA: false,
    LogicalKeyboardKey.keyS: false,
    LogicalKeyboardKey.keyD: false,
    LogicalKeyboardKey.space: false,

    LogicalKeyboardKey.arrowUp: false,
    LogicalKeyboardKey.arrowLeft: false,
    LogicalKeyboardKey.arrowDown: false,
    LogicalKeyboardKey.arrowRight: false,
  };

  Vector3 vector1 = Vector3();
  Vector3 vector2 = Vector3();
  Vector3 vector3 = Vector3();

  @override
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    disposed = true;
    three3dRender.dispose();
    super.dispose();
  }
  
  void initSize(BuildContext context) {
    print('here');
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }
  void animate() {
    if (!mounted || disposed) {
      return;
    }
    double deltaTime = Math.min(0.05, clock.getDelta())/stepsPerFrame;
    if(deltaTime != 0){
      for (int i = 0; i < stepsPerFrame; i ++) {
        controls(deltaTime);
        updatePlayer(deltaTime);
        updateSpheres(deltaTime);
        teleportPlayerIfOob();
      }
    }
    render();

    Future.delayed(const Duration(milliseconds: 40), () {
      animate();
    });
  }
  Future<void> initPage() async {
    scene = Scene();
    scene.background = THREE.Color(0x88ccee);

    camera = PerspectiveCamera(70, width / height, 0.1, 1000);
    camera.rotation.order = 'YXZ';

    // lights
    HemisphereLight fillLight1 = HemisphereLight( 0x4488bb, 0x002244, 0.5 );
    fillLight1.position.set( 2, 1, 1 );
    scene.add(fillLight1);

    DirectionalLight directionalLight = DirectionalLight( 0xffffff, 0.8 );
    directionalLight.position.set( - 5, 25, - 1 );
    directionalLight.castShadow = true;

    directionalLight.shadow!.camera!.near = 0.01;
    directionalLight.shadow!.camera!.far = 500;
    directionalLight.shadow!.camera!.right = 30;
    directionalLight.shadow!.camera!.left = - 30;
    directionalLight.shadow!.camera!.top	= 30;
    directionalLight.shadow!.camera!.bottom = - 30;
    directionalLight.shadow!.mapSize.width = 1024;
    directionalLight.shadow!.mapSize.height = 1024;
    directionalLight.shadow!.radius = 4;
    directionalLight.shadow!.bias = - 0.00006;

    scene.add(directionalLight);

    GLTFLoader().setPath('assets/models/glb/').load('collision-world.glb', (gltf){
      Object3D object = gltf["scene"];
      scene.add(object);
      worldOctree.fromGraphNode(object);

      OctreeHelper helper = OctreeHelper(worldOctree);
      helper.visible = true;
      scene.add(helper);

      object.traverse((child){
        if(child.type == 'Mesh'){
          Mesh part = child;
          part.castShadow = true;
          part.visible = true;
          part.receiveShadow = true;
        }
      });
    });

    animationReady = true;
  }
  void render() {
    final _gl = three3dRender.gl;
    renderer!.render(scene, camera);
    _gl.flush();
    if(!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }
  void initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element,
    };

    if(!kIsWeb && Platform.isAndroid){
      _options['logarithmicDepthBuffer'] = true;
    }

    renderer = WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    if(!kIsWeb){
      WebGLRenderTargetOptions pars = WebGLRenderTargetOptions({"format": RGBAFormat,"samples": 8});
      renderTarget = WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget!.samples = 8;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
    else{
      renderTarget = null;
    }
  }
  void initScene() async{
    await initPage();
    initRenderer();
    animate();
  }
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": true,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
      'precision': 'highp'
    };
    await three3dRender.initialize(options: _options);

    setState(() {});

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();
      initScene();
    });
  }

  void throwBall() {
    double sphereRadius = 0.2;
    THREE.IcosahedronGeometry sphereGeometry = THREE.IcosahedronGeometry( sphereRadius, 5 );
    MeshLambertMaterial sphereMaterial = MeshLambertMaterial({'color': 0xbbbb44});

    final Mesh newsphere = Mesh( sphereGeometry, sphereMaterial );
    newsphere.castShadow = true;
    newsphere.receiveShadow = true;

    scene.add( newsphere );
    spheres.add(SphereData(
      mesh: newsphere,
      collider: Sphere(Vector3( 0, - 100, 0 ), sphereRadius),
      velocity: Vector3()
    ));
    SphereData sphere = spheres.last;
    camera.getWorldDirection( playerDirection );
    sphere.collider.center.copy(playerCollider.end).addScaledVector( playerDirection, playerCollider.radius * 1.5 );
    // throw the ball with more force if we hold the button longer, and if we move forward
    double impulse = 15 + 30 * ( 1 - Math.exp((mouseTime-DateTime.now().millisecondsSinceEpoch) * 0.001));
    sphere.velocity.copy( playerDirection ).multiplyScalar( impulse );
    sphere.velocity.addScaledVector( playerVelocity, 2 );
    sphereIdx = ( sphereIdx + 1 ) % spheres.length;
  }
  
  void playerCollisions() {
    OctreeData? result = worldOctree.capsuleIntersect(playerCollider);
    playerOnFloor = false;
    if(result != null){
      playerOnFloor = result.normal.y > 0;
      if(!playerOnFloor) {
        playerVelocity.addScaledVector(result.normal, - result.normal.dot(playerVelocity));
      }
      if(result.depth > 0.02){
        playerCollider.translate(result.normal.multiplyScalar(result.depth));
      }
    }
  }
  void updatePlayer(double deltaTime) {
    double damping = Math.exp(-4 * deltaTime) -1;
    if(!playerOnFloor){
      playerVelocity.y -= gravity * deltaTime;
      // small air resistance
      damping *= 0.1;
    }

    playerVelocity.addScaledVector( playerVelocity, damping );
    Vector3 deltaPosition = playerVelocity.clone().multiplyScalar( deltaTime );
    playerCollider.translate( deltaPosition );
    playerCollisions();
    camera.position.copy(playerCollider.end);
  }
  void playerSphereCollision(SphereData sphere) {
    Vector3 center = vector1.addVectors(playerCollider.start, playerCollider.end ).multiplyScalar( 0.5 );
    final sphereCenter = sphere.collider.center;
    double r = playerCollider.radius + sphere.collider.radius;
    double r2 = r*r;

    // approximation: player = 3 spheres
    List<Vector3> temp = [playerCollider.start,playerCollider.end,center];
    for(Vector3 point in temp) {
      num d2 = point.distanceToSquared(sphereCenter);
      if ( d2 < r2 ) {
        Vector3 normal = vector1.subVectors(point, sphereCenter).normalize();
        Vector3 v1 = vector2.copy( normal ).multiplyScalar( normal.dot( playerVelocity ) );
        Vector3 v2 = vector3.copy( normal ).multiplyScalar( normal.dot( sphere.velocity) );

        playerVelocity.add(v2).sub(v1);
        sphere.velocity.add(v1).sub(v2);

        double d = ( r - Math.sqrt( d2 ) ) / 2;
        sphereCenter.addScaledVector( normal, - d );
      }
    }
  }
  
  void spheresCollisions() {
    for (int i = 0, length = spheres.length; i < length; i ++ ) {
      SphereData s1 = spheres[ i ];
      for (int j = i + 1; j < length; j ++ ) {
        SphereData s2 = spheres[ j ];
        num d2 = s1.collider.center.distanceToSquared(s2.collider.center);
        double r = s1.collider.radius + s2.collider.radius;
        double r2 = r * r;

        if ( d2 < r2 ) {
          Vector3 normal = vector1.subVectors( s1.collider.center, s2.collider.center ).normalize();
          Vector3 v1 = vector2.copy( normal ).multiplyScalar( normal.dot( s1.velocity));
          Vector3 v2 = vector3.copy( normal ).multiplyScalar( normal.dot( s2.velocity));

          s1.velocity.add( v2 ).sub( v1 );
          s2.velocity.add( v1 ).sub( v2 );

          double d = ( r - Math.sqrt( d2 ) ) / 2;

          s1.collider.center.addScaledVector( normal, d );
          s2.collider.center.addScaledVector( normal, - d );
        }
      }
    }
  }
  void updateSpheres(double deltaTime) {
    spheres.forEach((sphere) {
      sphere.collider.center.addScaledVector(sphere.velocity, deltaTime);
      OctreeData? result = worldOctree.sphereIntersect(sphere.collider);
      if(result != null) {
        sphere.velocity.addScaledVector( result.normal, - result.normal.dot( sphere.velocity) * 1.5 );
        sphere.collider.center.add( result.normal.multiplyScalar( result.depth ) );
      } 
      else{
        sphere.velocity.y -= gravity * deltaTime;
      }

      double damping = Math.exp(- 1.5*deltaTime) - 1;
      sphere.velocity.addScaledVector(sphere.velocity, damping);

      playerSphereCollision(sphere);
    });

    spheresCollisions();

    for (SphereData sphere in spheres){
      sphere.mesh.position.copy(sphere.collider.center);
    }
  }

  Vector3 getForwardVector() {
    camera.getWorldDirection(playerDirection);
    playerDirection.y = 0;
    playerDirection.normalize();
    return playerDirection;
  }
  Vector3 getSideVector() {
    camera.getWorldDirection( playerDirection );
    playerDirection.y = 0;
    playerDirection.normalize();
    playerDirection.cross( camera.up );
    return playerDirection;
  }
  void controls(double deltaTime){
    // gives a bit of air control
    double speedDelta = deltaTime*(playerOnFloor?25:8);

    if(keyStates[LogicalKeyboardKey.keyW]! || keyStates[LogicalKeyboardKey.arrowUp]!){
      playerVelocity.add( getForwardVector().multiplyScalar(speedDelta));
    }
    if(keyStates[LogicalKeyboardKey.keyS]! || keyStates[LogicalKeyboardKey.arrowDown]!){
      playerVelocity.add( getForwardVector().multiplyScalar(-speedDelta));
    }
    if(keyStates[LogicalKeyboardKey.keyA]! || keyStates[LogicalKeyboardKey.arrowLeft]!){
      playerVelocity.add( getSideVector().multiplyScalar(-speedDelta));
    }
    if (keyStates[LogicalKeyboardKey.keyD]! || keyStates[LogicalKeyboardKey.arrowRight]!){
      playerVelocity.add( getSideVector().multiplyScalar(speedDelta));
    }
    if(playerOnFloor){
      if(keyStates[LogicalKeyboardKey.space]!){
        playerVelocity.y = 15;
      }
    }
  }
  void teleportPlayerIfOob(){
    if(camera.position.y <= - 25){
      playerCollider.start.set(0,0.35,0);
      playerCollider.end.set(0,1,0);
      playerCollider.radius = 0.35;
      camera.position.copy(playerCollider.end);
      camera.rotation.set(0,0,0);
    }
  }

  Widget threeDart() {
    return Builder(builder: (BuildContext context) {
      initSize(context);
      return Container(
        width: screenSize!.width,
        height: screenSize!.height,
        color: Theme.of(context).canvasColor,
        child: RawKeyboardListener(
          focusNode: node,
          onKey: (event){
            if(event is RawKeyDownEvent){
              if(
                event.data.logicalKey == LogicalKeyboardKey.keyW || 
                event.data.logicalKey == LogicalKeyboardKey.keyA || 
                event.data.logicalKey == LogicalKeyboardKey.keyS || 
                event.data.logicalKey == LogicalKeyboardKey.keyD || 
                event.data.logicalKey == LogicalKeyboardKey.arrowUp || 
                event.data.logicalKey == LogicalKeyboardKey.arrowLeft || 
                event.data.logicalKey == LogicalKeyboardKey.arrowDown || 
                event.data.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.data.logicalKey == LogicalKeyboardKey.space
              ){
                keyStates[event.data.logicalKey] = true;
              }
            }
            else if(event is RawKeyUpEvent){
              if(
                event.data.logicalKey == LogicalKeyboardKey.keyW || 
                event.data.logicalKey == LogicalKeyboardKey.keyA || 
                event.data.logicalKey == LogicalKeyboardKey.keyS || 
                event.data.logicalKey == LogicalKeyboardKey.keyD ||
                event.data.logicalKey == LogicalKeyboardKey.arrowUp || 
                event.data.logicalKey == LogicalKeyboardKey.arrowLeft || 
                event.data.logicalKey == LogicalKeyboardKey.arrowDown || 
                event.data.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.data.logicalKey == LogicalKeyboardKey.space
              ){
                keyStates[event.data.logicalKey] = false;
              }
            }
          },
          child: Listener(
            onPointerDown: (details){
              mouseTime = DateTime.now().millisecondsSinceEpoch;
            },
            onPointerUp: (details){
              throwBall();
            },
            onPointerHover: (PointerHoverEvent details){
              if(animationReady){
                camera.rotation.y -= details.delta.dx/100;
                camera.rotation.x -= details.delta.dy/100;
              }
            },
            child: DomLikeListenable(
              key: _globalKey,
              builder: (BuildContext context) {
                FocusScope.of(context).requestFocus(node);
                return Container(
                  width: width,
                  height: height,
                  color: Theme.of(context).canvasColor,
                  child: Builder(builder: (BuildContext context) {
                    if (kIsWeb) {
                      return three3dRender.isInitialized
                          ? HtmlElementView(
                              viewType:
                                  three3dRender.textureId!.toString())
                          : Container();
                    } else {
                      return three3dRender.isInitialized
                          ? Texture(textureId: three3dRender.textureId!)
                          : Container();
                    }
                  })
                );
              }),
          )
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Stack(
        children: [
          threeDart(),
        ],
      )
    );
  }
}