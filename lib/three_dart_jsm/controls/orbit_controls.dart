part of jsm_controls;

// This set of controls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
//
//    Orbit - left mouse / touch: one-finger move
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - right mouse, or left mouse + ctrl/meta/shiftKey, or arrow keys / touch: two-finger move

class State {
  static const int none = -1;
  static const int rotate = 0;
  static const int dolly = 1;
  static const int zoom = 1;
  static const int pan = 2;
  static const int touchRotate = 3;
  static const int touchPan = 4;
  static const int touchZoomPan = 4;
  static const int touchDollyPan = 5;
  static const int touchDollyRotate = 6;
}

// The four arrow keys
class Keys {
  static const String left = 'ArrowLeft';
  static const String up = 'ArrowUp';
  static const String right = 'ArrowRight';
  static const String bottom = 'ArrowDown';
}

class OrbitControls with EventDispatcher {
  late OrbitControls scope;
  late Camera object;

  late GlobalKey<DomLikeListenableState> listenableKey;
  DomLikeListenableState get domElement => listenableKey.currentState!;

  // API
  late bool enabled;
  late Vector3 target;
  late Vector3 target0;
  late Vector3 position0;
  late double zoom0;

  late double minDistance;
  late double maxDistance;

  late double minZoom;
  late double maxZoom;

  late double minPolarAngle;
  late double maxPolarAngle;

  late double minAzimuthAngle;
  late double maxAzimuthAngle;

  late bool enableDamping;
  late double dampingFactor;

  late bool enableZoom;
  late double zoomSpeed;

  late bool enableRotate;
  late double rotateSpeed;

  late bool enablePan;
  late double panSpeed;
  late bool screenSpacePanning;
  late double keyPanSpeed;

  late bool autoRotate;
  late double autoRotateSpeed;

  late bool enableKeys;

  late Map<String, dynamic> mouseButtons;
  late Map<String, dynamic> touches;

  var changeEvent = Event({"type": 'change'});
  var startEvent = Event({"type": 'start'});
  var endEvent = Event({"type": 'end'});

  var state = State.none;

  var eps = 0.000001;

  // current position in spherical coordinates
  var spherical = Spherical();
  var sphericalDelta = Spherical();

  num scale = 1;
  var panOffset = Vector3.init();
  var zoomChanged = false;

  var rotateStart = Vector2(0, 0);
  var rotateEnd = Vector2(null, null);
  var rotateDelta = Vector2(null, null);

  var panStart = Vector2(null, null);
  var panEnd = Vector2(null, null);
  var panDelta = Vector2(null, null);

  var dollyStart = Vector2(null, null);
  var dollyEnd = Vector2(null, null);
  var dollyDelta = Vector2(null, null);

  var infinity = Math.infinity;

  List pointers = [];
  Map<int, Vector2> pointerPositions = {};

  var lastPosition = Vector3();
  var lastQuaternion = Quaternion();

  var twoPI = 2 * Math.pi;

  late Quaternion quat;
  late Quaternion quatInverse;

  OrbitControls(this.object, this.listenableKey) : super() {
    scope = this;

    // this.domElement = domElement;
    // this.domElement.style.touchAction = 'none'; // disable touch scroll

    // Set to false to disable this control
    enabled = true;

    // "target" sets the location of focus, where the object orbits around
    target = Vector3();

    // How far you can dolly in and out ( PerspectiveCamera only )
    minDistance = 0;
    maxDistance = infinity;

    // How far you can zoom in and out ( OrthographicCamera only )
    minZoom = 0;
    maxZoom = infinity;

    // How far you can orbit vertically, upper and lower limits.
    // Range is 0 to Math.pi radians.
    minPolarAngle = 0; // radians
    maxPolarAngle = Math.pi; // radians

    // How far you can orbit horizontally, upper and lower limits.
    // If set, the interval [ min, max ] must be a sub-interval of [ - 2 PI, 2 PI ], with ( max - min < 2 PI )
    minAzimuthAngle = -infinity; // radians
    maxAzimuthAngle = infinity; // radians

    // Set to true to enable damping (inertia)
    // If damping is enabled, you must call controls.update() in your animation loop
    enableDamping = false;
    dampingFactor = 0.05;

    // This option actually enables dollying in and out; left as "zoom" for backwards compatibility.
    // Set to false to disable zooming
    enableZoom = true;
    zoomSpeed = 1.0;

    // Set to false to disable rotating
    enableRotate = true;
    rotateSpeed = 1.0;

    // Set to false to disable panning
    enablePan = true;
    panSpeed = 1.0;
    screenSpacePanning = true; // if false, pan orthogonal to world-space direction camera.up
    keyPanSpeed = 7.0; // pixels moved per arrow key push

    // Set to true to automatically rotate around the target
    // If auto-rotate is enabled, you must call controls.update() in your animation loop
    autoRotate = false;
    autoRotateSpeed = 2.0; // 30 seconds per orbit when fps is 60

    // Mouse buttons
    mouseButtons = {'LEFT': MOUSE.ROTATE, 'MIDDLE': MOUSE.DOLLY, 'RIGHT': MOUSE.PAN};

    // Touch fingers
    touches = {'ONE': TOUCH.ROTATE, 'TWO': TOUCH.DOLLY_PAN};

    // for reset
    target0 = target.clone();
    position0 = object.position.clone();
    zoom0 = object.zoom;

    // the target DOM element for key events
    // this._domElementKeyEvents = null;

    scope.domElement.addEventListener('contextmenu', onContextMenu);

    scope.domElement.addEventListener('pointerdown', onPointerDown);
    scope.domElement.addEventListener('pointercancel', onPointerCancel);
    scope.domElement.addEventListener('wheel', onMouseWheel);

    // force an update at start

    // so camera.up is the orbit axis
    quat = Quaternion().setFromUnitVectors(object.up, Vector3(0, 1, 0));
    quatInverse = quat.clone().invert();

    update();
  }

  getPolarAngle() {
    return spherical.phi;
  }

  getAzimuthalAngle() {
    return spherical.theta;
  }

  getDistance() {
    return object.position.distanceTo(target);
  }

  listenToKeyEvents(domElement) {
    domElement.addEventListener('keydown', onKeyDown);
    // this._domElementKeyEvents = domElement;
  }

  saveState() {
    scope.target0.copy(scope.target);
    scope.position0.copy(scope.object.position);
    scope.zoom0 = scope.object.zoom;
  }

  reset() {
    scope.target.copy(scope.target0);
    scope.object.position.copy(scope.position0);
    scope.object.zoom = scope.zoom0;

    scope.object.updateProjectionMatrix();
    scope.dispatchEvent(_changeEvent);

    scope.update();

    state = State.none;
  }

  // this method is exposed, but perhaps it would be better if we can make it private...

  var offset = Vector3();

  update() {
    var position = scope.object.position;
    offset.copy(position).sub(scope.target);

    // rotate offset to "y-axis-is-up" space
    offset.applyQuaternion(quat);

    // angle from z-axis around y-axis
    spherical.setFromVector3(offset);

    if (scope.autoRotate && state == State.none) {
      rotateLeft(getAutoRotationAngle());
    }

    if (scope.enableDamping) {
      spherical.theta += sphericalDelta.theta * scope.dampingFactor;
      spherical.phi += sphericalDelta.phi * scope.dampingFactor;
    } else {
      spherical.theta += sphericalDelta.theta;
      spherical.phi += sphericalDelta.phi;
    }

    // restrict theta to be between desired limits

    var min = scope.minAzimuthAngle;
    var max = scope.maxAzimuthAngle;

    if (isFinite(min) && isFinite(max)) {
      if (min < -Math.pi) {
        min += twoPI;
      } else if (min > Math.pi) {
        min -= twoPI;
      }

      if (max < -Math.pi) {
        max += twoPI;
      } else if (max > Math.pi) {
        max -= twoPI;
      }

      if (min <= max) {
        spherical.theta = Math.max(min, Math.min(max, spherical.theta));
      } else {
        spherical.theta =
            (spherical.theta > (min + max) / 2) ? Math.max(min, spherical.theta) : Math.min(max, spherical.theta);
      }
    }

    // restrict phi to be between desired limits
    spherical.phi = Math.max(scope.minPolarAngle, Math.min(scope.maxPolarAngle, spherical.phi));

    spherical.makeSafe();

    spherical.radius *= scale;

    // restrict radius to be between desired limits
    spherical.radius = Math.max(scope.minDistance, Math.min(scope.maxDistance, spherical.radius));

    // move target to panned location

    if (scope.enableDamping == true) {
      scope.target.addScaledVector(panOffset, scope.dampingFactor);
    } else {
      scope.target.add(panOffset);
    }

    offset.setFromSpherical(spherical);

    // rotate offset back to "camera-up-vector-is-up" space
    offset.applyQuaternion(quatInverse);
    position.copy(scope.target).add(offset);

    scope.object.lookAt(scope.target);

    if (scope.enableDamping == true) {
      sphericalDelta.theta *= (1 - scope.dampingFactor);
      sphericalDelta.phi *= (1 - scope.dampingFactor);

      panOffset.multiplyScalar(1 - scope.dampingFactor);
    } else {
      sphericalDelta.set(0, 0, 0);

      panOffset.set(0, 0, 0);
    }

    scale = 1;

    // update condition is:
    // min(camera displacement, camera rotation in radians)^2 > EPS
    // using small-angle approximation cos(x/2) = 1 - x^2 / 8

    if (zoomChanged ||
        lastPosition.distanceToSquared(scope.object.position) > eps ||
        8 * (1 - lastQuaternion.dot(scope.object.quaternion)) > eps) {
      scope.dispatchEvent(_changeEvent);

      lastPosition.copy(scope.object.position);
      lastQuaternion.copy(scope.object.quaternion);
      zoomChanged = false;

      return true;
    }

    return false;
  }

  dispose() {
    scope.domElement.removeEventListener('contextmenu', onContextMenu);

    scope.domElement.removeEventListener('pointerdown', onPointerDown);
    scope.domElement.removeEventListener('pointercancel', onPointerCancel);
    scope.domElement.removeEventListener('wheel', onMouseWheel);

    scope.domElement.removeEventListener('pointermove', onPointerMove);
    scope.domElement.removeEventListener('pointerup', onPointerUp);

    // if ( scope._domElementKeyEvents != null ) {

    //   scope._domElementKeyEvents.removeEventListener( 'keydown', onKeyDown );

    // }

    //scope.dispatchEvent( { type: 'dispose' } ); // should this be added here?
  }

  getAutoRotationAngle() {
    return 2 * Math.pi / 60 / 60 * scope.autoRotateSpeed;
  }

  getZoomScale() {
    return Math.pow(0.95, scope.zoomSpeed);
  }

  rotateLeft(angle) {
    sphericalDelta.theta -= angle;
  }

  rotateUp(angle) {
    sphericalDelta.phi -= angle;
  }

  var v = Vector3();

  panLeft(distance, objectMatrix) {
    v.setFromMatrixColumn(objectMatrix, 0); // get X column of objectMatrix
    v.multiplyScalar(-distance);

    panOffset.add(v);
  }

  panUp(distance, objectMatrix) {
    if (scope.screenSpacePanning == true) {
      v.setFromMatrixColumn(objectMatrix, 1);
    } else {
      v.setFromMatrixColumn(objectMatrix, 0);
      v.crossVectors(scope.object.up, v);
    }

    v.multiplyScalar(distance);

    panOffset.add(v);
  }

  // deltaX and deltaY are in pixels; right and down are positive
  pan(deltaX, deltaY) {
    var element = scope.domElement;

    if (scope.object is PerspectiveCamera) {
      // perspective
      var position = scope.object.position;
      offset.copy(position).sub(scope.target);
      var targetDistance = offset.length();

      // half of the fov is center to top of screen
      targetDistance *= Math.tan((scope.object.fov / 2) * Math.pi / 180.0);

      // we use only clientHeight here so aspect ratio does not distort speed
      panLeft(2 * deltaX * targetDistance / element.clientHeight, scope.object.matrix);
      panUp(2 * deltaY * targetDistance / element.clientHeight, scope.object.matrix);
    } else if (scope.object is OrthographicCamera) {
      // orthographic
      panLeft(deltaX * (scope.object.right - scope.object.left) / scope.object.zoom / element.clientWidth,
          scope.object.matrix);
      panUp(deltaY * (scope.object.top - scope.object.bottom) / scope.object.zoom / element.clientHeight,
          scope.object.matrix);
    } else {
      // camera neither orthographic nor perspective
      print('WARNING: OrbitControls.js encountered an unknown camera type - pan disabled.');
      scope.enablePan = false;
    }
  }

  dollyOut(dollyScale) {
    if (scope.object is PerspectiveCamera) {
      scale /= dollyScale;
    } else if (scope.object is OrthographicCamera) {
      scope.object.zoom = Math.max(scope.minZoom, Math.min(scope.maxZoom, scope.object.zoom * dollyScale));
      scope.object.updateProjectionMatrix();
      zoomChanged = true;
    } else {
      print('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
      scope.enableZoom = false;
    }
  }

  dollyIn(dollyScale) {
    if (scope.object is PerspectiveCamera) {
      scale *= dollyScale;
    } else if (scope.object is OrthographicCamera) {
      scope.object.zoom = Math.max(scope.minZoom, Math.min(scope.maxZoom, scope.object.zoom / dollyScale));
      scope.object.updateProjectionMatrix();
      zoomChanged = true;
    } else {
      print('WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled.');
      scope.enableZoom = false;
    }
  }

  //
  // event callbacks - update the object state
  //

  handleMouseDownRotate(event) {
    rotateStart.set(event.clientX, event.clientY);
  }

  handleMouseDownDolly(event) {
    dollyStart.set(event.clientX, event.clientY);
  }

  handleMouseDownPan(event) {
    panStart.set(event.clientX, event.clientY);
  }

  handleMouseMoveRotate(event) {
    rotateEnd.set(event.clientX, event.clientY);

    rotateDelta.subVectors(rotateEnd, rotateStart).multiplyScalar(scope.rotateSpeed);

    var element = scope.domElement;

    rotateLeft(2 * Math.pi * rotateDelta.x / element.clientHeight); // yes, height

    rotateUp(2 * Math.pi * rotateDelta.y / element.clientHeight);

    rotateStart.copy(rotateEnd);

    scope.update();
  }

  handleMouseMoveDolly(event) {
    dollyEnd.set(event.clientX, event.clientY);

    dollyDelta.subVectors(dollyEnd, dollyStart);

    if (dollyDelta.y > 0) {
      dollyOut(getZoomScale());
    } else if (dollyDelta.y < 0) {
      dollyIn(getZoomScale());
    }

    dollyStart.copy(dollyEnd);

    scope.update();
  }

  handleMouseMovePan(event) {
    panEnd.set(event.clientX, event.clientY);

    panDelta.subVectors(panEnd, panStart).multiplyScalar(scope.panSpeed);

    pan(panDelta.x, panDelta.y);

    panStart.copy(panEnd);

    scope.update();
  }

  handleMouseWheel(event) {
    if (event.deltaY < 0) {
      dollyIn(getZoomScale());
    } else if (event.deltaY > 0) {
      dollyOut(getZoomScale());
    }

    scope.update();
  }

  handleKeyDown(event) {
    var needsUpdate = false;

    switch (event.code) {
      case Keys.up:
        pan(0, scope.keyPanSpeed);
        needsUpdate = true;
        break;

      case Keys.bottom:
        pan(0, -scope.keyPanSpeed);
        needsUpdate = true;
        break;

      case Keys.left:
        pan(scope.keyPanSpeed, 0);
        needsUpdate = true;
        break;

      case Keys.right:
        pan(-scope.keyPanSpeed, 0);
        needsUpdate = true;
        break;
    }

    if (needsUpdate) {
      // prevent the browser from scrolling on cursor keys
      event.preventDefault();

      scope.update();
    }
  }

  handleTouchStartRotate() {
    if (pointers.length == 1) {
      rotateStart.set(pointers[0].pageX, pointers[0].pageY);
    } else {
      var x = 0.5 * (pointers[0].pageX + pointers[1].pageX);
      var y = 0.5 * (pointers[0].pageY + pointers[1].pageY);

      rotateStart.set(x, y);
    }
  }

  handleTouchStartPan() {
    if (pointers.length == 1) {
      panStart.set(pointers[0].pageX, pointers[0].pageY);
    } else {
      var x = 0.5 * (pointers[0].pageX + pointers[1].pageX);
      var y = 0.5 * (pointers[0].pageY + pointers[1].pageY);

      panStart.set(x, y);
    }
  }

  handleTouchStartDolly() {
    var dx = pointers[0].pageX - pointers[1].pageX;
    var dy = pointers[0].pageY - pointers[1].pageY;

    var distance = Math.sqrt(dx * dx + dy * dy);

    dollyStart.set(0, distance);
  }

  handleTouchStartDollyPan() {
    if (scope.enableZoom) handleTouchStartDolly();

    if (scope.enablePan) handleTouchStartPan();
  }

  handleTouchStartDollyRotate() {
    if (scope.enableZoom) handleTouchStartDolly();

    if (scope.enableRotate) handleTouchStartRotate();
  }

  handleTouchMoveRotate(event) {
    if (pointers.length == 1) {
      rotateEnd.set(event.pageX, event.pageY);
    } else {
      var position = getSecondPointerPosition(event);

      var x = 0.5 * (event.pageX + position.x);
      var y = 0.5 * (event.pageY + position.y);

      rotateEnd.set(x, y);
    }

    rotateDelta.subVectors(rotateEnd, rotateStart).multiplyScalar(scope.rotateSpeed);

    var element = scope.domElement;

    rotateLeft(2 * Math.pi * rotateDelta.x / element.clientHeight); // yes, height

    rotateUp(2 * Math.pi * rotateDelta.y / element.clientHeight);

    rotateStart.copy(rotateEnd);
  }

  handleTouchMovePan(event) {
    if (pointers.length == 1) {
      panEnd.set(event.pageX, event.pageY);
    } else {
      var position = getSecondPointerPosition(event);

      var x = 0.5 * (event.pageX + position.x);
      var y = 0.5 * (event.pageY + position.y);

      panEnd.set(x, y);
    }

    panDelta.subVectors(panEnd, panStart).multiplyScalar(scope.panSpeed);

    pan(panDelta.x, panDelta.y);

    panStart.copy(panEnd);
  }

  handleTouchMoveDolly(event) {
    var position = getSecondPointerPosition(event);

    print("handleTouchMoveDolly event.pageX: ${event.pageX} position.x: ${position.x} ");
    print("handleTouchMoveDolly event.pageY: ${event.pageY} position.y: ${position.y} ");

    var dx = event.pageX - position.x;
    var dy = event.pageY - position.y;

    var distance = Math.sqrt(dx * dx + dy * dy);

    dollyEnd.set(0, distance);

    dollyDelta.set(0, Math.pow(dollyEnd.y / dollyStart.y, scope.zoomSpeed).toDouble());

    dollyOut(dollyDelta.y);

    dollyStart.copy(dollyEnd);
  }

  handleTouchMoveDollyPan(event) {
    if (scope.enableZoom) handleTouchMoveDolly(event);

    if (scope.enablePan) handleTouchMovePan(event);
  }

  handleTouchMoveDollyRotate(event) {
    if (scope.enableZoom) handleTouchMoveDolly(event);

    if (scope.enableRotate) handleTouchMoveRotate(event);
  }

  //
  // event handlers - FSM: listen for events and reset state
  //

  onPointerDown(event) {
    if (scope.enabled == false) return;

    if (pointers.isEmpty) {
      scope.domElement.setPointerCapture(event.pointerId);

      scope.domElement.addEventListener('pointermove', onPointerMove);
      scope.domElement.addEventListener('pointerup', onPointerUp);
    }

    addPointer(event);

    if (event.pointerType == 'touch') {
      onTouchStart(event);
    } else {
      onMouseDown(event);
    }
  }

  onPointerMove(event) {
    if (scope.enabled == false) return;

    if (event.pointerType == 'touch') {
      onTouchMove(event);
    } else {
      onMouseMove(event);
    }
  }

  onPointerUp(event) {
    removePointer(event);

    if (pointers.isEmpty) {
      scope.domElement.releasePointerCapture(event.pointerId);

      scope.domElement.removeEventListener('pointermove', onPointerMove);
      scope.domElement.removeEventListener('pointerup', onPointerUp);
    }

    scope.dispatchEvent(_endEvent);

    state = State.none;
  }

  onPointerCancel(event) {
    removePointer(event);
  }

  onMouseDown(event) {
    var mouseAction;

    switch (event.button) {
      case 0:
        mouseAction = scope.mouseButtons['LEFT'];
        break;

      case 1:
        mouseAction = scope.mouseButtons['MIDDLE'];
        break;

      case 2:
        mouseAction = scope.mouseButtons['RIGHT'];
        break;

      default:
        mouseAction = -1;
    }

    switch (mouseAction) {
      case MOUSE.DOLLY:
        if (scope.enableZoom == false) return;

        handleMouseDownDolly(event);

        state = State.dolly;

        break;

      case MOUSE.ROTATE:
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
          if (scope.enablePan == false) return;

          handleMouseDownPan(event);

          state = State.pan;
        } else {
          if (scope.enableRotate == false) return;

          handleMouseDownRotate(event);

          state = State.rotate;
        }

        break;

      case MOUSE.PAN:
        if (event.ctrlKey || event.metaKey || event.shiftKey) {
          if (scope.enableRotate == false) return;

          handleMouseDownRotate(event);

          state = State.rotate;
        } else {
          if (scope.enablePan == false) return;

          handleMouseDownPan(event);

          state = State.pan;
        }

        break;

      default:
        state = State.none;
    }

    if (state != State.none) {
      scope.dispatchEvent(_startEvent);
    }
  }

  onMouseMove(event) {
    if (scope.enabled == false) return;

    switch (state) {
      case State.rotate:
        if (scope.enableRotate == false) return;

        handleMouseMoveRotate(event);

        break;

      case State.dolly:
        if (scope.enableZoom == false) return;

        handleMouseMoveDolly(event);

        break;

      case State.pan:
        if (scope.enablePan == false) return;

        handleMouseMovePan(event);

        break;
    }
  }

  onMouseWheel(event) {
    if (scope.enabled == false || scope.enableZoom == false || state != State.none) return;

    event.preventDefault();

    scope.dispatchEvent(_startEvent);

    handleMouseWheel(event);

    scope.dispatchEvent(_endEvent);
  }

  onKeyDown(event) {
    if (scope.enabled == false || scope.enablePan == false) return;

    handleKeyDown(event);
  }

  onTouchStart(event) {
    trackPointer(event);

    switch (pointers.length) {
      case 1:
        switch (scope.touches['ONE']) {
          case TOUCH.ROTATE:
            if (scope.enableRotate == false) return;

            handleTouchStartRotate();

            state = State.touchRotate;

            break;

          case TOUCH.PAN:
            if (scope.enablePan == false) return;

            handleTouchStartPan();

            state = State.touchPan;

            break;

          default:
            state = State.none;
        }

        break;

      case 2:
        switch (scope.touches['TWO']) {
          case TOUCH.DOLLY_PAN:
            if (scope.enableZoom == false && scope.enablePan == false) return;

            handleTouchStartDollyPan();

            state = State.touchDollyPan;

            break;

          case TOUCH.DOLLY_ROTATE:
            if (scope.enableZoom == false && scope.enableRotate == false) return;

            handleTouchStartDollyRotate();

            state = State.touchDollyRotate;

            break;

          default:
            state = State.none;
        }

        break;

      default:
        state = State.none;
    }

    if (state != State.none) {
      scope.dispatchEvent(_startEvent);
    }
  }

  onTouchMove(event) {
    trackPointer(event);

    switch (state) {
      case State.touchRotate:
        if (scope.enableRotate == false) return;

        handleTouchMoveRotate(event);

        scope.update();

        break;

      case State.touchPan:
        if (scope.enablePan == false) return;

        handleTouchMovePan(event);

        scope.update();

        break;

      case State.touchDollyPan:
        if (scope.enableZoom == false && scope.enablePan == false) return;

        handleTouchMoveDollyPan(event);

        scope.update();

        break;

      case State.touchDollyRotate:
        if (scope.enableZoom == false && scope.enableRotate == false) return;

        handleTouchMoveDollyRotate(event);

        scope.update();

        break;

      default:
        state = State.none;
    }
  }

  onContextMenu(event) {
    if (scope.enabled == false) return;

    event.preventDefault();
  }

  addPointer(event) {
    pointers.add(event);
  }

  removePointer(event) {
    pointerPositions.remove(event.pointerId);

    for (var i = 0; i < pointers.length; i++) {
      if (pointers[i].pointerId == event.pointerId) {
        pointers.splice(i, 1);
        return;
      }
    }
  }

  trackPointer(event) {
    var position = pointerPositions[event.pointerId];

    if (position == null) {
      position = Vector2();
      pointerPositions[event.pointerId] = position;
    }

    position.set(event.pageX, event.pageY);
  }

  getSecondPointerPosition(event) {
    var pointer = (event.pointerId == pointers[0].pointerId) ? pointers[1] : pointers[0];

    return pointerPositions[pointer.pointerId];
  }
}

// This set of controls performs orbiting, dollying (zooming), and panning.
// Unlike TrackballControls, it maintains the "up" direction object.up (+Y by default).
// This is very similar to OrbitControls, another set of touch behavior
//
//    Orbit - right mouse, or left mouse + ctrl/meta/shiftKey / touch: two-finger rotate
//    Zoom - middle mouse, or mousewheel / touch: two-finger spread or squish
//    Pan - left mouse, or arrow keys / touch: one-finger move

class MapControls extends OrbitControls {
  MapControls(object, domElement) : super(object, domElement) {
    screenSpacePanning = false; // pan orthogonal to world-space direction camera.up

    mouseButtons['LEFT'] = MOUSE.PAN;
    mouseButtons['RIGHT'] = MOUSE.ROTATE;

    touches['ONE'] = TOUCH.PAN;
    touches['TWO'] = TOUCH.DOLLY_ROTATE;
  }
}
