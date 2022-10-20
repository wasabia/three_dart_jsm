part of jsm_controls;

class TrackballControls with EventDispatcher {
  late TrackballControls scope;
  late Camera object;

  late GlobalKey<DomLikeListenableState> listenableKey;
  DomLikeListenableState get domElement => listenableKey.currentState!;

  bool enabled = true;

  Map screen = {'left': 0, 'top': 0, 'width': 0, 'height': 0};

  double rotateSpeed = 1.0;
  double zoomSpeed = 1.2;
  double panSpeed = 0.3;

  bool noRotate = false;
  bool noZoom = false;
  bool noPan = false;

  bool staticMoving = false;
  double dynamicDampingFactor = 0.2;

  double minDistance = 0;
  double maxDistance = Math.infinity;

  List<String> keys = ['KeyA' /*A*/, 'KeyS' /*S*/, 'KeyD' /*D*/];

  Map mouseButtons = {'LEFT': MOUSE.ROTATE, 'MIDDLE': MOUSE.DOLLY, 'RIGHT': MOUSE.PAN};

  // internals

  Vector3 target = Vector3();

  var eps = 0.000001;

  var lastPosition = Vector3();
  var lastZoom = 1.0;

  var _state = State.none,
      _keyState = State.none,
      _touchZoomDistanceStart = 0.0,
      _touchZoomDistanceEnd = 0.0,
      _lastAngle = 0.0;

  final _eye = Vector3(),
      _movePrev = Vector2(),
      _moveCurr = Vector2(),
      _lastAxis = Vector3(),
      _zoomStart = Vector2(),
      _zoomEnd = Vector2(),
      _panStart = Vector2(),
      _panEnd = Vector2(),
      _pointers = [],
      _pointerPositions = {};

  late Vector3 target0;
  late Vector3 position0;
  late Vector3 up0;
  late double zoom0;

  TrackballControls(this.object, this.listenableKey) : super() {
    scope = this;

    // this.domElement.style.touchAction = 'none'; // disable touch scroll

    // API

    // for reset

    target0 = target.clone();
    position0 = object.position.clone();
    up0 = object.up.clone();
    zoom0 = object.zoom;

    domElement.addEventListener('contextmenu', contextmenu);

    domElement.addEventListener('pointerdown', onPointerDown);
    domElement.addEventListener('pointercancel', onPointerCancel);
    domElement.addEventListener('wheel', onMouseWheel);

    // TODO
    // window.addEventListener( 'keydown', keydown );
    // window.addEventListener( 'keyup', keyup );

    handleResize();

    // force an update at start
    update();
  }

  // methods

  handleResize() {
    RenderBox getBox = listenableKey.currentContext?.findRenderObject() as RenderBox;
    var size = getBox.size;
    var local = getBox.globalToLocal(Offset(0, 0));

    screen['left'] = local.dx;
    screen['top'] = local.dy;
    screen['width'] = size.width;
    screen['height'] = size.height;

    // var box = scope.domElement.getBoundingClientRect();
    // adjustments come from similar code in the jquery offset() function
    // var d = scope.domElement.ownerDocument.documentElement;
    // scope.screen.left = box.left + window.pageXOffset - d.clientLeft;
    // scope.screen.top = box.top + window.pageYOffset - d.clientTop;
    // scope.screen.width = box.width;
    // scope.screen.height = box.height;
  }

  var vector = Vector2();

  getMouseOnScreen(pageX, pageY) {
    vector.set(
        (pageX - scope.screen['left']) / scope.screen['width'], (pageY - scope.screen['top']) / scope.screen['height']);

    return vector;
  }

  getMouseOnCircle(pageX, pageY) {
    vector.set(
        ((pageX - scope.screen['width'] * 0.5 - scope.screen['left']) / (scope.screen['width'] * 0.5)),
        ((scope.screen['height'] + 2 * (scope.screen['top'] - pageY)) /
            scope.screen['width']) // screen.width intentional
        );

    return vector;
  }

  var axis = Vector3(),
      quaternion = Quaternion(),
      eyeDirection = Vector3(),
      objectUpDirection = Vector3(),
      objectSidewaysDirection = Vector3(),
      moveDirection = Vector3();

  rotateCamera() {
    moveDirection.set(_moveCurr.x - _movePrev.x, _moveCurr.y - _movePrev.y, 0);
    var angle = moveDirection.length();

    if (angle != 0) {
      _eye.copy(scope.object.position).sub(scope.target);

      eyeDirection.copy(_eye).normalize();
      objectUpDirection.copy(scope.object.up).normalize();
      objectSidewaysDirection.crossVectors(objectUpDirection, eyeDirection).normalize();

      objectUpDirection.setLength(_moveCurr.y - _movePrev.y);
      objectSidewaysDirection.setLength(_moveCurr.x - _movePrev.x);

      moveDirection.copy(objectUpDirection.add(objectSidewaysDirection));

      axis.crossVectors(moveDirection, _eye).normalize();

      angle *= scope.rotateSpeed;
      quaternion.setFromAxisAngle(axis, angle);

      _eye.applyQuaternion(quaternion);
      scope.object.up.applyQuaternion(quaternion);

      _lastAxis.copy(axis);
      _lastAngle = angle;
    } else if (!scope.staticMoving && _lastAngle != 0) {
      _lastAngle *= Math.sqrt(1.0 - scope.dynamicDampingFactor);
      _eye.copy(scope.object.position).sub(scope.target);
      quaternion.setFromAxisAngle(_lastAxis, _lastAngle);
      _eye.applyQuaternion(quaternion);
      scope.object.up.applyQuaternion(quaternion);
    }

    _movePrev.copy(_moveCurr);
  }

  zoomCamera() {
    var factor;

    if (_state == State.touchZoomPan) {
      factor = _touchZoomDistanceStart / _touchZoomDistanceEnd;
      _touchZoomDistanceStart = _touchZoomDistanceEnd;

      if (scope.object is PerspectiveCamera) {
        _eye.multiplyScalar(factor);
      } else if (scope.object is OrthographicCamera) {
        scope.object.zoom /= factor;
        scope.object.updateProjectionMatrix();
      } else {
        print('THREE.TrackballControls: Unsupported camera type');
      }
    } else {
      factor = 1.0 + (_zoomEnd.y - _zoomStart.y) * scope.zoomSpeed;

      if (factor != 1.0 && factor > 0.0) {
        if (scope.object is PerspectiveCamera) {
          _eye.multiplyScalar(factor);
        } else if (scope.object is OrthographicCamera) {
          scope.object.zoom /= factor;
          scope.object.updateProjectionMatrix();
        } else {
          print('THREE.TrackballControls: Unsupported camera type');
        }
      }

      if (scope.staticMoving) {
        _zoomStart.copy(_zoomEnd);
      } else {
        _zoomStart.y += (_zoomEnd.y - _zoomStart.y) * dynamicDampingFactor;
      }
    }
  }

  var mouseChange = Vector2(), objectUp = Vector3(), pan = Vector3();

  panCamera() {
    mouseChange.copy(_panEnd).sub(_panStart);

    if (mouseChange.lengthSq() != 0) {
      if (scope.object is OrthographicCamera) {
        var scaleX = (scope.object.right - scope.object.left) / scope.object.zoom / scope.domElement.clientWidth;
        var scaleY = (scope.object.top - scope.object.bottom) / scope.object.zoom / scope.domElement.clientWidth;

        mouseChange.x *= scaleX;
        mouseChange.y *= scaleY;
      }

      mouseChange.multiplyScalar(_eye.length() * scope.panSpeed);

      pan.copy(_eye).cross(scope.object.up).setLength(mouseChange.x);
      pan.add(objectUp.copy(scope.object.up).setLength(mouseChange.y));

      scope.object.position.add(pan);
      scope.target.add(pan);

      if (scope.staticMoving) {
        _panStart.copy(_panEnd);
      } else {
        _panStart.add(mouseChange.subVectors(_panEnd, _panStart).multiplyScalar(scope.dynamicDampingFactor));
      }
    }
  }

  checkDistances() {
    if (!scope.noZoom || !scope.noPan) {
      if (_eye.lengthSq() > scope.maxDistance * scope.maxDistance) {
        scope.object.position.addVectors(scope.target, _eye.setLength(scope.maxDistance));
        _zoomStart.copy(_zoomEnd);
      }

      if (_eye.lengthSq() < scope.minDistance * scope.minDistance) {
        scope.object.position.addVectors(scope.target, _eye.setLength(scope.minDistance));
        _zoomStart.copy(_zoomEnd);
      }
    }
  }

  update() {
    _eye.subVectors(scope.object.position, scope.target);

    if (!scope.noRotate) {
      scope.rotateCamera();
    }

    if (!scope.noZoom) {
      scope.zoomCamera();
    }

    if (!scope.noPan) {
      scope.panCamera();
    }

    scope.object.position.addVectors(scope.target, _eye);

    if (scope.object is PerspectiveCamera) {
      scope.checkDistances();

      scope.object.lookAt(scope.target);

      if (lastPosition.distanceToSquared(scope.object.position) > eps) {
        scope.dispatchEvent(_changeEvent);

        lastPosition.copy(scope.object.position);
      }
    } else if (scope.object is OrthographicCamera) {
      scope.object.lookAt(scope.target);

      if (lastPosition.distanceToSquared(scope.object.position) > eps || lastZoom != scope.object.zoom) {
        scope.dispatchEvent(_changeEvent);

        lastPosition.copy(scope.object.position);
        lastZoom = scope.object.zoom;
      }
    } else {
      print('THREE.TrackballControls: Unsupported camera type');
    }
  }

  reset() {
    _state = State.none;
    _keyState = State.none;

    scope.target.copy(scope.target0);
    scope.object.position.copy(scope.position0);
    scope.object.up.copy(scope.up0);
    scope.object.zoom = scope.zoom0;

    scope.object.updateProjectionMatrix();

    _eye.subVectors(scope.object.position, scope.target);

    scope.object.lookAt(scope.target);

    scope.dispatchEvent(_changeEvent);

    lastPosition.copy(scope.object.position);
    lastZoom = scope.object.zoom;
  }

  // listeners

  onPointerDown(event) {
    if (scope.enabled == false) return;

    if (_pointers.isEmpty) {
      scope.domElement.setPointerCapture(event.pointerId);

      scope.domElement.addEventListener('pointermove', onPointerMove);
      scope.domElement.addEventListener('pointerup', onPointerUp);
    }

    //

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
    if (scope.enabled == false) return;

    if (event.pointerType == 'touch') {
      onTouchEnd(event);
    } else {
      onMouseUp();
    }

    //

    removePointer(event);

    if (_pointers.isEmpty) {
      scope.domElement.releasePointerCapture(event.pointerId);

      scope.domElement.removeEventListener('pointermove', onPointerMove);
      scope.domElement.removeEventListener('pointerup', onPointerUp);
    }
  }

  onPointerCancel(event) {
    removePointer(event);
  }

  keydown(event) {
    if (scope.enabled == false) return;

    // TODO
    // window.removeEventListener( 'keydown', keydown );

    if (_keyState != State.none) {
      return;
    } else if (event.code == scope.keys[State.rotate] && !scope.noRotate) {
      _keyState = State.rotate;
    } else if (event.code == scope.keys[State.zoom] && !scope.noZoom) {
      _keyState = State.zoom;
    } else if (event.code == scope.keys[State.pan] && !scope.noPan) {
      _keyState = State.pan;
    }
  }

  keyup() {
    if (scope.enabled == false) return;

    _keyState = State.none;

    // TODO
    // window.addEventListener( 'keydown', keydown );
  }

  onMouseDown(event) {
    if (_state == State.none) {
      if (event.button == scope.mouseButtons['LEFT']) {
        _state = State.rotate;
      } else if (event.button == scope.mouseButtons['MIDDLE']) {
        _state = State.zoom;
      } else if (event.button == scope.mouseButtons['RIGHT']) {
        _state = State.pan;
      }
    }

    var state = (_keyState != State.none) ? _keyState : _state;

    if (state == State.rotate && !scope.noRotate) {
      _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
      _movePrev.copy(_moveCurr);
    } else if (state == State.zoom && !scope.noZoom) {
      _zoomStart.copy(getMouseOnScreen(event.pageX, event.pageY));
      _zoomEnd.copy(_zoomStart);
    } else if (state == State.pan && !scope.noPan) {
      _panStart.copy(getMouseOnScreen(event.pageX, event.pageY));
      _panEnd.copy(_panStart);
    }

    scope.dispatchEvent(_startEvent);
  }

  onMouseMove(event) {
    var state = (_keyState != State.none) ? _keyState : _state;

    if (state == State.rotate && !scope.noRotate) {
      _movePrev.copy(_moveCurr);
      _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
    } else if (state == State.zoom && !scope.noZoom) {
      _zoomEnd.copy(getMouseOnScreen(event.pageX, event.pageY));
    } else if (state == State.pan && !scope.noPan) {
      _panEnd.copy(getMouseOnScreen(event.pageX, event.pageY));
    }
  }

  onMouseUp() {
    _state = State.none;

    scope.dispatchEvent(_endEvent);
  }

  onMouseWheel(event) {
    if (scope.enabled == false) return;

    if (scope.noZoom == true) return;

    event.preventDefault();

    switch (event.deltaMode) {
      case 2:
        // Zoom in pages
        _zoomStart.y -= event.deltaY * 0.025;
        break;

      case 1:
        // Zoom in lines
        _zoomStart.y -= event.deltaY * 0.01;
        break;

      default:
        // undefined, 0, assume pixels
        _zoomStart.y -= event.deltaY * 0.00025;
        break;
    }

    scope.dispatchEvent(_startEvent);
    scope.dispatchEvent(_endEvent);
  }

  onTouchStart(event) {
    trackPointer(event);

    switch (_pointers.length) {
      case 1:
        _state = State.touchRotate;
        _moveCurr.copy(getMouseOnCircle(_pointers[0].pageX, _pointers[0].pageY));
        _movePrev.copy(_moveCurr);
        break;

      default: // 2 or more
        _state = State.touchZoomPan;
        var dx = _pointers[0].pageX - _pointers[1].pageX;
        var dy = _pointers[0].pageY - _pointers[1].pageY;
        _touchZoomDistanceEnd = _touchZoomDistanceStart = Math.sqrt(dx * dx + dy * dy);

        var x = (_pointers[0].pageX + _pointers[1].pageX) / 2;
        var y = (_pointers[0].pageY + _pointers[1].pageY) / 2;
        _panStart.copy(getMouseOnScreen(x, y));
        _panEnd.copy(_panStart);
        break;
    }

    scope.dispatchEvent(_startEvent);
  }

  onTouchMove(event) {
    trackPointer(event);

    switch (_pointers.length) {
      case 1:
        _movePrev.copy(_moveCurr);
        _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
        break;

      default: // 2 or more

        var position = getSecondPointerPosition(event);

        var dx = event.pageX - position.x;
        var dy = event.pageY - position.y;
        _touchZoomDistanceEnd = Math.sqrt(dx * dx + dy * dy);

        var x = (event.pageX + position.x) / 2;
        var y = (event.pageY + position.y) / 2;
        _panEnd.copy(getMouseOnScreen(x, y));
        break;
    }
  }

  onTouchEnd(event) {
    switch (_pointers.length) {
      case 0:
        _state = State.none;
        break;

      case 1:
        _state = State.touchRotate;
        _moveCurr.copy(getMouseOnCircle(event.pageX, event.pageY));
        _movePrev.copy(_moveCurr);
        break;

      case 2:
        _state = State.touchZoomPan;
        _moveCurr.copy(getMouseOnCircle(event.pageX - _movePrev.x, event.pageY - _movePrev.y));
        _movePrev.copy(_moveCurr);
        break;
    }

    scope.dispatchEvent(_endEvent);
  }

  contextmenu(event) {
    if (scope.enabled == false) return;

    event.preventDefault();
  }

  addPointer(event) {
    _pointers.add(event);
  }

  removePointer(event) {
    _pointerPositions.remove(event.pointerId);

    for (var i = 0; i < _pointers.length; i++) {
      if (_pointers[i].pointerId == event.pointerId) {
        _pointers.splice(i, 1);
        return;
      }
    }
  }

  trackPointer(event) {
    var position = _pointerPositions[event.pointerId];

    if (position == null) {
      position = Vector2();
      _pointerPositions[event.pointerId] = position;
    }

    position.set(event.pageX, event.pageY);
  }

  getSecondPointerPosition(event) {
    var pointer = (event.pointerId == _pointers[0].pointerId) ? _pointers[1] : _pointers[0];

    return _pointerPositions[pointer.pointerId];
  }

  dispose() {
    scope.domElement.removeEventListener('contextmenu', contextmenu);

    scope.domElement.removeEventListener('pointerdown', onPointerDown);
    scope.domElement.removeEventListener('pointercancel', onPointerCancel);
    scope.domElement.removeEventListener('wheel', onMouseWheel);

    scope.domElement.removeEventListener('pointermove', onPointerMove);
    scope.domElement.removeEventListener('pointerup', onPointerUp);

    // TODO
    // window.removeEventListener( 'keydown', keydown );
    // window.removeEventListener( 'keyup', keyup );
  }
}
