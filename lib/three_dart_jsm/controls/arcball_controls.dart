part of jsm_controls;

//trackball state
class State2 {
  static const int idle = 0;
  static const int rotate = 1;
  static const int pan = 2;
  static const int scale = 3;
  static const int fov = 4;
  static const int focus = 5;
  static const int zRotate = 6;
  static const int touchMulti = 7;
  static const int animationFocus = 8;
  static const int animationRotate = 9;
}

class Input {
  static const int none = 0;
  static const int oneFinger = 1;
  static const int oneFingerSwitched = 2;
  static const int twoFinger = 3;
  static const int multiFinger = 4;
  static const int cursor = 5;
}

//cursor center coordinates
Vector2 _center = Vector2(0, 0);

//transformation matrices for gizmos and camera
var _transformation = {'camera': Matrix4(), 'gizmos': Matrix4()};

var _gizmoMatrixStateTemp = Matrix4();
var _cameraMatrixStateTemp = Matrix4();
var _scalePointTemp = Vector3();

/// @param {Camera} camera Virtual camera used in the scene
/// @param {HTMLElement} domElement Renderer's dom element
/// @param {Scene} scene The scene to be rendered
class ArcballControls with EventDispatcher {
  Vector3 target = Vector3();
  final _currentTarget = Vector3();
  var radiusFactor = 0.67;

  var mouseActions = [];
  dynamic _mouseOp;

  //global vectors and matrices that are used in some operations to avoid creating new objects every time (e.g. every time cursor moves)
  final _v2_1 = Vector2();
  final _v3_1 = Vector3();
  final _v3_2 = Vector3();

  final _m4_1 = Matrix4();
  final _m4_2 = Matrix4();

  final _quat = Quaternion();

  //transformation matrices
  final _translationMatrix = Matrix4(); //matrix for translation operation
  final _rotationMatrix = Matrix4(); //matrix for rotation operation
  final _scaleMatrix = Matrix4(); //matrix for scaling operation

  final _rotationAxis = Vector3(); //axis for rotate operation

  //camera state
  final _cameraMatrixState = Matrix4();
  final _cameraProjectionState = Matrix4();

  num _fovState = 1;
  final _upState = Vector3();
  double _zoomState = 1;
  num _nearPos = 0;
  num _farPos = 0;

  final _gizmoMatrixState = Matrix4();

  //initial values
  final _up0 = Vector3();
  double _zoom0 = 1;
  num _fov0 = 0;
  num _initialNear = 0;
  num _nearPos0 = 0;
  num _initialFar = 0;
  num _farPos0 = 0;
  final _cameraMatrixState0 = Matrix4();
  final _gizmoMatrixState0 = Matrix4();

  //pointers array
  var _button = -1;
  final _touchStart = [];
  final _touchCurrent = [];
  var _input = Input.none;

  //two fingers touch interaction
  //minimum movement to be performed to fire single pan start after the second finger has been released
  final _switchSensibility = 32;
  var _startFingerDistance = 0; //distance between two fingers
  var _currentFingerDistance = 0;
  var _startFingerRotation = 0; //amount of rotation performed with two fingers
  var _currentFingerRotation = 0;

  //double tap
  var _devPxRatio = 0;
  var _downValid = true;
  var _nclicks = 0;
  final _downEvents = [];
  var _clickStart = 0; //first click time
  final _maxDownTime = 250;
  final _maxInterval = 300;
  final _posThreshold = 24;
  final _movementThreshold = 24;

  //cursor positions
  final _currentCursorPosition = Vector3();
  final _startCursorPosition = Vector3();

  //grid
  var _grid; //grid to be visualized during pan operation
  final _gridPosition = Vector3();

  //gizmos
  final _gizmos = Group();
  final _curvePts = 128;

  //animations
  var _timeStart = -1; //initial time
  dynamic _animationId = -1;

  //focus animation
  var focusAnimationTime = 500; //duration of focus animation in ms

  //rotate animation
  var _timePrev = 0; //time at which previous rotate operation has been detected
  var _timeCurrent = 0; //time at which current rotate operation has been detected
  num _anglePrev = 0; //angle of previous rotation
  num _angleCurrent = 0; //angle of current rotation
  final _cursorPosPrev = Vector3(); //cursor position when previous rotate operation has been detected
  final _cursorPosCurr = Vector3(); //cursor position when current rotate operation has been detected
  double _wPrev = 0; //angular velocity of the previous rotate operation
  double _wCurr = 0; //angular velocity of the current rotate operation

  //parameters
  var adjustNearFar = false;
  var scaleFactor = 1.1; //zoom/distance multiplier
  var dampingFactor = 25;
  var wMax = 20; //maximum angular velocity allowed
  var enableAnimations = true; //if animations should be performed
  var enableGrid = false; //if grid should be showed during pan operation
  var cursorZoom = false; //if wheel zoom should be cursor centered
  double minFov = 5;
  double maxFov = 90;

  var enabled = true;
  var enablePan = true;
  var enableRotate = true;
  var enableZoom = true;
  var enableGizmos = true;

  double minDistance = 0;
  double maxDistance = infinity;
  double minZoom = 0;
  double maxZoom = infinity;

  //trackball parameters
  double _tbRadius = 1;

  late OrbitControls scope;
  late Camera camera;

  late GlobalKey<DomLikeListenableState> listenableKey;
  DomLikeListenableState get domElement => listenableKey.currentState!;

  Scene? scene;
  dynamic _state;

  ArcballControls(camera, this.listenableKey, [scene, devicePixelRatio = 1.0]) : super() {
    _state = State2.idle;

    setCamera(camera);

    if (scene != null) {
      scene!.add(_gizmos);
    }

    // domElement.style.touchAction = 'none';
    _devPxRatio = devicePixelRatio;

    initializeMouseActions();

    domElement.addEventListener('contextmenu', onContextMenu);
    domElement.addEventListener('wheel', onWheel);
    domElement.addEventListener('pointerdown', onPointerDown);
    domElement.addEventListener('pointercancel', onPointerCancel);

    // window.addEventListener( 'resize', onWindowResize );
  }

  //listeners

  onWindowResize() {
    var scale = (_gizmos.scale.x + _gizmos.scale.y + _gizmos.scale.z) / 3;
    _tbRadius = calculateTbRadius(camera);

    var newRadius = _tbRadius / scale;
    var curve = EllipseCurve(0, 0, newRadius, newRadius);
    var points = curve.getPoints(_curvePts);
    var curveGeometry = BufferGeometry().setFromPoints(points);

    for (var gizmo in _gizmos.children) {
      // _gizmos.children[ gizmo ].geometry = curveGeometry;
      gizmo.geometry = curveGeometry;
    }

    dispatchEvent(_changeEvent);
  }

  onContextMenu(event) {
    if (!enabled) {
      return;
    }

    for (var i = 0; i < mouseActions.length; i++) {
      if (mouseActions[i]['mouse'] == 2) {
        //prevent only if button 2 is actually used
        event.preventDefault();
        break;
      }
    }
  }

  onPointerCancel() {
    _touchStart.splice(0, _touchStart.length);
    _touchCurrent.splice(0, _touchCurrent.length);
    _input = Input.none;
  }

  onPointerDown(event) {
    if (event.button == 0 && event.isPrimary) {
      _downValid = true;
      _downEvents.add(event);
    } else {
      _downValid = false;
    }

    if (event.pointerType == 'touch' && _input != Input.cursor) {
      _touchStart.add(event);
      _touchCurrent.add(event);

      switch (_input) {
        case Input.none:

          //singleStart
          _input = Input.oneFinger;
          onSinglePanStart(event, 'ROTATE');

          domElement.addEventListener('pointermove', onPointerMove);
          domElement.addEventListener('pointerup', onPointerUp);

          break;

        case Input.oneFinger:
        case Input.oneFingerSwitched:

          //doubleStart
          _input = Input.twoFinger;

          onRotateStart();
          onPinchStart();
          onDoublePanStart();

          break;

        case Input.twoFinger:

          //multipleStart
          _input = Input.multiFinger;
          onTriplePanStart(event);
          break;
      }
    } else if (event.pointerType != 'touch' && _input == Input.none) {
      String? modifier;
      if (event.ctrlKey || event.metaKey) {
        modifier = 'CTRL';
      } else if (event.shiftKey) {
        modifier = 'SHIFT';
      }

      _mouseOp = getOpFromAction(event.button, modifier);

      if (_mouseOp != null) {
        domElement.addEventListener('pointermove', onPointerMove);
        domElement.addEventListener('pointerup', onPointerUp);

        //singleStart
        _input = Input.cursor;
        _button = event.button;
        onSinglePanStart(event, _mouseOp);
      }
    }
  }

  onPointerMove(event) {
    if (event.pointerType == 'touch' && _input != Input.cursor) {
      switch (_input) {
        case Input.oneFinger:

          //singleMove
          updateTouchEvent(event);

          onSinglePanMove(event, State2.rotate);
          break;

        case Input.oneFingerSwitched:
          var movement = calculatePointersDistance(_touchCurrent[0], event) * _devPxRatio;

          if (movement >= _switchSensibility) {
            //singleMove
            _input = Input.oneFinger;
            updateTouchEvent(event);

            onSinglePanStart(event, 'ROTATE');
            break;
          }

          break;

        case Input.twoFinger:

          //rotate/pan/pinchMove
          updateTouchEvent(event);

          onRotateMove();
          onPinchMove();
          onDoublePanMove();

          break;

        case Input.multiFinger:

          //multMove
          updateTouchEvent(event);

          onTriplePanMove(event);
          break;
      }
    } else if (event.pointerType != 'touch' && _input == Input.cursor) {
      String? modifier;

      if (event.ctrlKey || event.metaKey) {
        modifier = 'CTRL';
      } else if (event.shiftKey) {
        modifier = 'SHIFT';
      }

      var mouseOpState = getOpStateFromAction(_button, modifier);

      if (mouseOpState != null) {
        onSinglePanMove(event, mouseOpState);
      }
    }

    //checkDistance
    if (_downValid) {
      var movement = calculatePointersDistance(_downEvents[_downEvents.length - 1], event) * _devPxRatio;
      if (movement > _movementThreshold) {
        _downValid = false;
      }
    }
  }

  onPointerUp(event) {
    if (event.pointerType == 'touch' && _input != Input.cursor) {
      var nTouch = _touchCurrent.length;

      for (var i = 0; i < nTouch; i++) {
        if (_touchCurrent[i].pointerId == event.pointerId) {
          _touchCurrent.splice(i, 1);
          _touchStart.splice(i, 1);
          break;
        }
      }

      switch (_input) {
        case Input.oneFinger:
        case Input.oneFingerSwitched:

          //singleEnd
          domElement.removeEventListener('pointermove', onPointerMove);
          domElement.removeEventListener('pointerup', onPointerUp);

          _input = Input.none;
          onSinglePanEnd();

          break;

        case Input.twoFinger:

          //doubleEnd
          onDoublePanEnd(event);
          onPinchEnd(event);
          onRotateEnd(event);

          //switching to singleStart
          _input = Input.oneFingerSwitched;

          break;

        case Input.multiFinger:
          if (_touchCurrent.isEmpty) {
            domElement.removeEventListener('pointermove', onPointerMove);
            domElement.removeEventListener('pointerup', onPointerUp);

            //multCancel
            _input = Input.none;
            onTriplePanEnd();
          }

          break;
      }
    } else if (event.pointerType != 'touch' && _input == Input.cursor) {
      domElement.removeEventListener('pointermove', onPointerMove);
      domElement.removeEventListener('pointerup', onPointerUp);

      _input = Input.none;
      onSinglePanEnd();
      _button = -1;
    }

    if (event.isPrimary) {
      if (_downValid) {
        var downTime = event.timeStamp - _downEvents[_downEvents.length - 1].timeStamp;

        if (downTime <= _maxDownTime) {
          if (_nclicks == 0) {
            //first valid click detected
            _nclicks = 1;
            _clickStart = DateTime.now().millisecondsSinceEpoch;
          } else {
            var clickInterval = event.timeStamp - _clickStart;
            var movement = calculatePointersDistance(_downEvents[1], _downEvents[0]) * _devPxRatio;

            if (clickInterval <= _maxInterval && movement <= _posThreshold) {
              //second valid click detected
              //fire double tap and reset values
              _nclicks = 0;
              _downEvents.splice(0, _downEvents.length);
              onDoubleTap(event);
            } else {
              //new 'first click'
              _nclicks = 1;
              _downEvents.removeAt(0);
              _clickStart = DateTime.now().millisecondsSinceEpoch;
            }
          }
        } else {
          _downValid = false;
          _nclicks = 0;
          _downEvents.splice(0, _downEvents.length);
        }
      } else {
        _nclicks = 0;
        _downEvents.splice(0, _downEvents.length);
      }
    }
  }

  onWheel(event) {
    if (enabled && enableZoom) {
      String? modifier;

      if (event.ctrlKey || event.metaKey) {
        modifier = 'CTRL';
      } else if (event.shiftKey) {
        modifier = 'SHIFT';
      }

      var mouseOp = getOpFromAction('WHEEL', modifier);

      if (mouseOp != null) {
        event.preventDefault();
        dispatchEvent(_startEvent);

        var notchDeltaY = 125; //distance of one notch of mouse wheel
        var sgn = event.deltaY / notchDeltaY;

        double size = 1;

        if (sgn > 0) {
          size = 1 / scaleFactor;
        } else if (sgn < 0) {
          size = scaleFactor;
        }

        switch (mouseOp) {
          case 'ZOOM':
            updateTbState(State2.scale, true);

            if (sgn > 0) {
              size = 1 / (Math.pow(scaleFactor, sgn));
            } else if (sgn < 0) {
              size = Math.pow(scaleFactor, -sgn) + 0.0;
            }

            if (cursorZoom && enablePan) {
              var scalePoint;

              if (camera is OrthographicCamera) {
                scalePoint = unprojectOnTbPlane(camera, event.clientX, event.clientY, domElement)
                    .applyQuaternion(camera.quaternion)
                    .multiplyScalar(1 / camera.zoom)
                    .add(_gizmos.position);
              } else if (camera is PerspectiveCamera) {
                scalePoint = unprojectOnTbPlane(camera, event.clientX, event.clientY, domElement)
                    .applyQuaternion(camera.quaternion)
                    .add(_gizmos.position);
              }

              applyTransformMatrix(scale(size, scalePoint));
            } else {
              applyTransformMatrix(scale(size, _gizmos.position));
            }

            if (_grid != null) {
              disposeGrid();
              drawGrid();
            }

            updateTbState(State2.idle, false);

            dispatchEvent(_changeEvent);
            dispatchEvent(_endEvent);

            break;

          case 'FOV':
            if (camera is PerspectiveCamera) {
              updateTbState(State2.fov, true);

              //Vertigo effect

              //	  fov / 2
              //		|\
              //		| \
              //		|  \
              //	x	|	\
              //		| 	 \
              //		| 	  \
              //		| _ _ _\
              //			y

              //check for iOs shift shortcut
              if (event.deltaX != 0) {
                sgn = event.deltaX / notchDeltaY;

                size = 1;

                if (sgn > 0) {
                  size = 1 / (Math.pow(scaleFactor, sgn));
                } else if (sgn < 0) {
                  size = Math.pow(scaleFactor, -sgn) + 0.0;
                }
              }

              _v3_1.setFromMatrixPosition(_cameraMatrixState);
              var x = _v3_1.distanceTo(_gizmos.position);
              var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

              //check min and max distance
              xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

              var y = x * Math.tan(MathUtils.deg2rad * camera.fov * 0.5);

              //calculate new fov
              var newFov = MathUtils.rad2deg * (Math.atan(y / xNew) * 2);

              //check min and max fov
              if (newFov > maxFov) {
                newFov = maxFov;
              } else if (newFov < minFov) {
                newFov = minFov;
              }

              var newDistance = y / Math.tan(MathUtils.deg2rad * (newFov / 2));
              size = x / newDistance;

              setFov(newFov);
              applyTransformMatrix(scale(size, _gizmos.position, false));
            }

            if (_grid != null) {
              disposeGrid();
              drawGrid();
            }

            updateTbState(State2.idle, false);

            dispatchEvent(_changeEvent);
            dispatchEvent(_endEvent);

            break;
        }
      }
    }
  }

  onSinglePanStart(event, operation) {
    if (enabled) {
      dispatchEvent(_startEvent);

      setCenter(event.clientX, event.clientY);

      switch (operation) {
        case 'PAN':
          if (!enablePan) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;

            activateGizmos(false);
            dispatchEvent(_changeEvent);
          }

          updateTbState(State2.pan, true);
          _startCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement));
          if (enableGrid) {
            drawGrid();
            dispatchEvent(_changeEvent);
          }

          break;

        case 'ROTATE':
          if (!enableRotate) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;
          }

          updateTbState(State2.rotate, true);
          _startCursorPosition.copy(unprojectOnTbSurface(camera, _center.x, _center.y, listenableKey, _tbRadius));
          activateGizmos(true);
          if (enableAnimations) {
            _timePrev = _timeCurrent = DateTime.now().millisecondsSinceEpoch;
            _angleCurrent = _anglePrev = 0;
            _cursorPosPrev.copy(_startCursorPosition);
            _cursorPosCurr.copy(_cursorPosPrev);
            _wCurr = 0;
            _wPrev = _wCurr;
          }

          dispatchEvent(_changeEvent);
          break;

        case 'FOV':
          if (camera is! PerspectiveCamera || !enableZoom) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;

            activateGizmos(false);
            dispatchEvent(_changeEvent);
          }

          updateTbState(State2.fov, true);
          _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
          _currentCursorPosition.copy(_startCursorPosition);
          break;

        case 'ZOOM':
          if (!enableZoom) {
            return;
          }

          if (_animationId != -1) {
            cancelAnimationFrame(_animationId);
            _animationId = -1;
            _timeStart = -1;

            activateGizmos(false);
            dispatchEvent(_changeEvent);
          }

          updateTbState(State2.scale, true);
          _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
          _currentCursorPosition.copy(_startCursorPosition);
          break;
      }
    }
  }

  onSinglePanMove(event, opState) {
    if (enabled) {
      var restart = opState != _state;
      setCenter(event.clientX, event.clientY);

      switch (opState) {
        case State2.pan:
          if (enablePan) {
            if (restart) {
              //switch to pan operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);

              _startCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement));
              if (enableGrid) {
                drawGrid();
              }

              activateGizmos(false);
            } else {
              //continue with pan operation
              _currentCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement));
              applyTransformMatrix(pan(_startCursorPosition, _currentCursorPosition));
            }
          }

          break;

        case State2.rotate:
          if (enableRotate) {
            if (restart) {
              //switch to rotate operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.copy(unprojectOnTbSurface(camera, _center.x, _center.y, listenableKey, _tbRadius));

              if (enableGrid) {
                disposeGrid();
              }

              activateGizmos(true);
            } else {
              //continue with rotate operation
              _currentCursorPosition.copy(unprojectOnTbSurface(camera, _center.x, _center.y, listenableKey, _tbRadius));

              var distance = _startCursorPosition.distanceTo(_currentCursorPosition);
              var angle = _startCursorPosition.angleTo(_currentCursorPosition);
              var amount = Math.max(distance / _tbRadius, angle); //effective rotation angle

              applyTransformMatrix(
                rotate(calculateRotationAxis(_startCursorPosition, _currentCursorPosition), amount),
              );

              if (enableAnimations) {
                _timePrev = _timeCurrent;
                _timeCurrent = DateTime.now().millisecondsSinceEpoch;
                _anglePrev = _angleCurrent;
                _angleCurrent = amount;
                _cursorPosPrev.copy(_cursorPosCurr);
                _cursorPosCurr.copy(_currentCursorPosition);
                _wPrev = _wCurr;
                _wCurr = calculateAngularSpeed(_anglePrev, _angleCurrent, _timePrev, _timeCurrent);
              }
            }
          }

          break;

        case State2.scale:
          if (enableZoom) {
            if (restart) {
              //switch to zoom operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
              _currentCursorPosition.copy(_startCursorPosition);

              if (enableGrid) {
                disposeGrid();
              }

              activateGizmos(false);
            } else {
              //continue with zoom operation
              var screenNotches = 8; //how many wheel notches corresponds to a full screen pan
              _currentCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);

              var movement = _currentCursorPosition.y - _startCursorPosition.y;

              num size = 1;

              if (movement < 0) {
                size = 1 / (Math.pow(scaleFactor, -movement * screenNotches));
              } else if (movement > 0) {
                size = Math.pow(scaleFactor, movement * screenNotches);
              }

              applyTransformMatrix(scale(size, _gizmos.position));
            }
          }

          break;

        case State2.fov:
          if (enableZoom && camera is PerspectiveCamera) {
            if (restart) {
              //switch to fov operation

              dispatchEvent(_endEvent);
              dispatchEvent(_startEvent);

              updateTbState(opState, true);
              _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
              _currentCursorPosition.copy(_startCursorPosition);

              if (enableGrid) {
                disposeGrid();
              }

              activateGizmos(false);
            } else {
              //continue with fov operation
              var screenNotches = 8; //how many wheel notches corresponds to a full screen pan
              _currentCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);

              var movement = _currentCursorPosition.y - _startCursorPosition.y;

              num size = 1;

              if (movement < 0) {
                size = 1 / (Math.pow(scaleFactor, -movement * screenNotches));
              } else if (movement > 0) {
                size = Math.pow(scaleFactor, movement * screenNotches);
              }

              _v3_1.setFromMatrixPosition(_cameraMatrixState);
              var x = _v3_1.distanceTo(_gizmos.position);
              var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

              //check min and max distance
              xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

              var y = x * Math.tan(MathUtils.deg2rad * _fovState * 0.5);

              //calculate new fov
              var newFov = MathUtils.rad2deg * (Math.atan(y / xNew) * 2);

              //check min and max fov
              newFov = MathUtils.clamp(newFov, minFov, maxFov);

              var newDistance = y / Math.tan(MathUtils.deg2rad * (newFov / 2));
              size = x / newDistance;
              _v3_2.setFromMatrixPosition(_gizmoMatrixState);

              setFov(newFov);
              applyTransformMatrix(scale(size, _v3_2, false));

              //adjusting distance
              _offset.copy(_gizmos.position).sub(camera.position).normalize().multiplyScalar(newDistance / x);
              _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);
            }
          }

          break;
      }

      dispatchEvent(_changeEvent);
    }
  }

  onSinglePanEnd() {
    if (_state == State2.rotate) {
      if (!enableRotate) {
        return;
      }

      if (enableAnimations) {
        //perform rotation animation
        var deltaTime = (DateTime.now().millisecondsSinceEpoch - _timeCurrent);
        if (deltaTime < 120) {
          var w = Math.abs((_wPrev + _wCurr) / 2);

          var self = this;
          _animationId = requestAnimationFrame((t) {
            self.updateTbState(State2.animationRotate, true);
            var rotationAxis = self.calculateRotationAxis(self._cursorPosPrev, self._cursorPosCurr);

            self.onRotationAnim(t, rotationAxis, Math.min(w, self.wMax));
          });
        } else {
          //cursor has been standing still for over 120 ms since last movement
          updateTbState(State2.idle, false);
          activateGizmos(false);
          dispatchEvent(_changeEvent);
        }
      } else {
        updateTbState(State2.idle, false);
        activateGizmos(false);
        dispatchEvent(_changeEvent);
      }
    } else if (_state == State2.pan || _state == State2.idle) {
      updateTbState(State2.idle, false);

      if (enableGrid) {
        disposeGrid();
      }

      activateGizmos(false);
      dispatchEvent(_changeEvent);
    }

    dispatchEvent(_endEvent);
  }

  onDoubleTap(event) {
    if (enabled && enablePan && scene != null) {
      dispatchEvent(_startEvent);

      setCenter(event.clientX, event.clientY);
      var hitP = unprojectOnObj(getCursorNDC(_center.x, _center.y, domElement), camera);

      if (hitP != null && enableAnimations) {
        var self = this;
        if (_animationId != -1) {
          cancelAnimationFrame(_animationId);
        }

        _timeStart = -1;
        _animationId = requestAnimationFrame((t) {
          self.updateTbState(State2.animationFocus, true);
          self.onFocusAnim(t, hitP, self._cameraMatrixState, self._gizmoMatrixState);
        });
      } else if (hitP != null && !enableAnimations) {
        updateTbState(State2.focus, true);
        focus(hitP, scaleFactor);
        updateTbState(State2.idle, false);
        dispatchEvent(_changeEvent);
      }
    }

    dispatchEvent(_endEvent);
  }

  onDoublePanStart() {
    if (enabled && enablePan) {
      dispatchEvent(_startEvent);

      updateTbState(State2.pan, true);

      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      _startCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
      _currentCursorPosition.copy(_startCursorPosition);

      activateGizmos(false);
    }
  }

  onDoublePanMove() {
    if (enabled && enablePan) {
      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);

      if (_state != State2.pan) {
        updateTbState(State2.pan, true);
        _startCursorPosition.copy(_currentCursorPosition);
      }

      _currentCursorPosition.copy(unprojectOnTbPlane(camera, _center.x, _center.y, domElement, true));
      applyTransformMatrix(pan(_startCursorPosition, _currentCursorPosition, true));
      dispatchEvent(_changeEvent);
    }
  }

  onDoublePanEnd(event) {
    updateTbState(State2.idle, false);
    dispatchEvent(_endEvent);
  }

  onRotateStart() {
    if (enabled && enableRotate) {
      dispatchEvent(_startEvent);

      updateTbState(State2.zRotate, true);

      //_startFingerRotation = event.rotation;

      _startFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);
      _currentFingerRotation = _startFingerRotation;

      camera.getWorldDirection(_rotationAxis); //rotation axis

      if (!enablePan && !enableZoom) {
        activateGizmos(true);
      }
    }
  }

  onRotateMove() {
    if (enabled && enableRotate) {
      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      var rotationPoint;

      if (_state != State2.zRotate) {
        updateTbState(State2.zRotate, true);
        _startFingerRotation = _currentFingerRotation;
      }

      //_currentFingerRotation = event.rotation;
      _currentFingerRotation = getAngle(_touchCurrent[1], _touchCurrent[0]) + getAngle(_touchStart[1], _touchStart[0]);

      if (!enablePan) {
        rotationPoint = Vector3().setFromMatrixPosition(_gizmoMatrixState);
      } else {
        _v3_2.setFromMatrixPosition(_gizmoMatrixState);
        rotationPoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement)
            .applyQuaternion(camera.quaternion)
            .multiplyScalar(1 / camera.zoom)
            .add(_v3_2);
      }

      var amount = MathUtils.deg2rad * (_startFingerRotation - _currentFingerRotation);

      applyTransformMatrix(zRotate(rotationPoint, amount));
      dispatchEvent(_changeEvent);
    }
  }

  onRotateEnd(event) {
    updateTbState(State2.idle, false);
    activateGizmos(false);
    dispatchEvent(_endEvent);
  }

  onPinchStart() {
    if (enabled && enableZoom) {
      dispatchEvent(_startEvent);
      updateTbState(State2.scale, true);

      _startFingerDistance = calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]);
      _currentFingerDistance = _startFingerDistance;

      activateGizmos(false);
    }
  }

  onPinchMove() {
    if (enabled && enableZoom) {
      setCenter((_touchCurrent[0].clientX + _touchCurrent[1].clientX) / 2,
          (_touchCurrent[0].clientY + _touchCurrent[1].clientY) / 2);
      var minDistance = 12; //minimum distance between fingers (in css pixels)

      if (_state != State2.scale) {
        _startFingerDistance = _currentFingerDistance;
        updateTbState(State2.scale, true);
      }

      _currentFingerDistance =
          Math.max(calculatePointersDistance(_touchCurrent[0], _touchCurrent[1]), minDistance * _devPxRatio);
      var amount = _currentFingerDistance / _startFingerDistance;

      var scalePoint;

      if (!enablePan) {
        scalePoint = _gizmos.position;
      } else {
        if (camera is OrthographicCamera) {
          scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement)
              .applyQuaternion(camera.quaternion)
              .multiplyScalar(1 / camera.zoom)
              .add(_gizmos.position);
        } else if (camera is PerspectiveCamera) {
          scalePoint = unprojectOnTbPlane(camera, _center.x, _center.y, domElement)
              .applyQuaternion(camera.quaternion)
              .add(_gizmos.position);
        }
      }

      applyTransformMatrix(scale(amount, scalePoint));
      dispatchEvent(_changeEvent);
    }
  }

  onPinchEnd(event) {
    updateTbState(State2.idle, false);
    dispatchEvent(_endEvent);
  }

  onTriplePanStart(event) {
    if (enabled && enableZoom) {
      dispatchEvent(_startEvent);

      updateTbState(State2.scale, true);

      //var center = event.center;
      num clientX = 0;
      num clientY = 0;
      var nFingers = _touchCurrent.length;

      for (var i = 0; i < nFingers; i++) {
        clientX += _touchCurrent[i]!.clientX;
        clientY += _touchCurrent[i]!.clientY;
      }

      setCenter(clientX / nFingers, clientY / nFingers);

      _startCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);
      _currentCursorPosition.copy(_startCursorPosition);
    }
  }

  onTriplePanMove(event) {
    if (enabled && enableZoom) {
      //	  fov / 2
      //		|\
      //		| \
      //		|  \
      //	x	|	\
      //		| 	 \
      //		| 	  \
      //		| _ _ _\
      //			y

      //var center = event.center;
      num clientX = 0;
      num clientY = 0;
      var nFingers = _touchCurrent.length;

      for (var i = 0; i < nFingers; i++) {
        clientX += _touchCurrent[i].clientX;
        clientY += _touchCurrent[i].clientY;
      }

      setCenter(clientX / nFingers, clientY / nFingers);

      var screenNotches = 8; //how many wheel notches corresponds to a full screen pan
      _currentCursorPosition.setY(getCursorNDC(_center.x, _center.y, domElement).y * 0.5);

      var movement = _currentCursorPosition.y - _startCursorPosition.y;

      num size = 1;

      if (movement < 0) {
        size = 1 / (Math.pow(scaleFactor, -movement * screenNotches));
      } else if (movement > 0) {
        size = Math.pow(scaleFactor, movement * screenNotches);
      }

      _v3_1.setFromMatrixPosition(_cameraMatrixState);
      var x = _v3_1.distanceTo(_gizmos.position);
      var xNew = x / size; //distance between camera and gizmos if scale(size, scalepoint) would be performed

      //check min and max distance
      xNew = MathUtils.clamp(xNew, minDistance, maxDistance);

      var y = x * Math.tan(MathUtils.deg2rad * _fovState * 0.5);

      //calculate new fov
      var newFov = MathUtils.rad2deg * (Math.atan(y / xNew) * 2);

      //check min and max fov
      newFov = MathUtils.clamp(newFov, minFov, maxFov);

      var newDistance = y / Math.tan(MathUtils.deg2rad * (newFov / 2));
      size = x / newDistance;
      _v3_2.setFromMatrixPosition(_gizmoMatrixState);

      setFov(newFov);
      applyTransformMatrix(scale(size, _v3_2, false));

      //adjusting distance
      _offset.copy(_gizmos.position).sub(camera.position).normalize().multiplyScalar(newDistance / x);
      _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

      dispatchEvent(_changeEvent);
    }
  }

  onTriplePanEnd() {
    updateTbState(State2.idle, false);
    dispatchEvent(_endEvent);
    //dispatchEvent( _changeEvent );
  }

  /// Set _center's x/y coordinates
  /// @param {Number} clientX
  /// @param {Number} clientY
  setCenter(clientX, clientY) {
    _center.x = clientX;
    _center.y = clientY;
  }

  /// Set default mouse actions
  initializeMouseActions() {
    setMouseAction('PAN', 0, 'CTRL');
    setMouseAction('PAN', 2);

    setMouseAction('ROTATE', 0);

    setMouseAction('ZOOM', 'WHEEL');
    setMouseAction('ZOOM', 1);

    setMouseAction('FOV', 'WHEEL', 'SHIFT');
    setMouseAction('FOV', 1, 'SHIFT');
  }

  /// Compare two mouse actions
  /// @param {Object} action1
  /// @param {Object} action2
  /// @returns {Boolean} True if action1 and action 2 are the same mouse action, false otherwise
  compareMouseAction(action1, action2) {
    if (action1['operation'] == action2['operation']) {
      if (action1['mouse'] == action2['mouse'] && action1['key'] == action2['key']) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  /// Set a new mouse action by specifying the operation to be performed and a mouse/key combination. In case of conflict, replaces the existing one
  /// @param {String} operation The operation to be performed ('PAN', 'ROTATE', 'ZOOM', 'FOV)
  /// @param {*} mouse A mouse button (0, 1, 2) or 'WHEEL' for wheel notches
  /// @param {*} key The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
  /// @returns {Boolean} True if the mouse action has been successfully added, false otherwise
  setMouseAction(String operation, mouse, [String? key]) {
    var operationInput = ['PAN', 'ROTATE', 'ZOOM', 'FOV'];
    var mouseInput = ['0', '1', '2', 'WHEEL'];
    var keyInput = ['CTRL', 'SHIFT', null];
    var state;

    if (!operationInput.contains(operation) || !mouseInput.contains(mouse.toString()) || !keyInput.contains(key)) {
      //invalid parameters
      return false;
    }

    if (mouse == 'WHEEL') {
      if (operation != 'ZOOM' && operation != 'FOV') {
        //cannot associate 2D operation to 1D input
        return false;
      }
    }

    switch (operation) {
      case 'PAN':
        state = State2.pan;
        break;

      case 'ROTATE':
        state = State2.rotate;
        break;

      case 'ZOOM':
        state = State2.scale;
        break;

      case 'FOV':
        state = State2.fov;
        break;
    }

    var action = {'operation': operation, 'mouse': mouse, 'key': key, 'state': state};

    for (var i = 0; i < mouseActions.length; i++) {
      if (mouseActions[i]['mouse'] == action['mouse'] && mouseActions[i]['key'] == action['key']) {
        mouseActions.splice(i, 1, action);
        return true;
      }
    }

    mouseActions.add(action);
    return true;
  }

  /// Remove a mouse action by specifying its mouse/key combination
  /// @param {*} mouse A mouse button (0, 1, 2) or 'WHEEL' for wheel notches
  /// @param {*} key The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
  /// @returns {Boolean} True if the operation has been succesfully removed, false otherwise
  unsetMouseAction(mouse, [String? key]) {
    for (var i = 0; i < mouseActions.length; i++) {
      if (mouseActions[i]['mouse'] == mouse && mouseActions[i]['key'] == key) {
        mouseActions.splice(i, 1);
        return true;
      }
    }

    return false;
  }

  /// Return the operation associated to a mouse/keyboard combination
  /// @param {*} mouse A mouse button (0, 1, 2) or 'WHEEL' for wheel notches
  /// @param {*} key The keyboard modifier ('CTRL', 'SHIFT') or null if key is not needed
  /// @returns The operation if it has been found, null otherwise
  getOpFromAction(mouse, key) {
    var action;

    for (var i = 0; i < mouseActions.length; i++) {
      action = mouseActions[i];
      if (action['mouse'] == mouse && action['key'] == key) {
        return action['operation'];
      }
    }

    if (key != null) {
      for (var i = 0; i < mouseActions.length; i++) {
        action = mouseActions[i];
        if (action['mouse'] == mouse && action['key'] == null) {
          return action['operation'];
        }
      }
    }

    return null;
  }

  /// Get the operation associated to mouse and key combination and returns the corresponding FSA state
  /// @param {Number} mouse Mouse button
  /// @param {String} key Keyboard modifier
  /// @returns The FSA state obtained from the operation associated to mouse/keyboard combination
  getOpStateFromAction(mouse, key) {
    var action;

    for (var i = 0; i < mouseActions.length; i++) {
      action = mouseActions[i];
      if (action['mouse'] == mouse && action['key'] == key) {
        return action['state'];
      }
    }

    if (key != null) {
      for (var i = 0; i < mouseActions.length; i++) {
        action = mouseActions[i];
        if (action['mouse'] == mouse && action['key'] == null) {
          return action['state'];
        }
      }
    }

    return null;
  }

  /// Calculate the angle between two pointers
  /// @param {PointerEvent} p1
  /// @param {PointerEvent} p2
  /// @returns {Number} The angle between two pointers in degrees
  getAngle(p1, p2) {
    return Math.atan2(p2.clientY - p1.clientY, p2.clientX - p1.clientX) * 180 / Math.pi;
  }

  /// Update a PointerEvent inside current pointerevents array
  /// @param {PointerEvent} event
  updateTouchEvent(event) {
    for (var i = 0; i < _touchCurrent.length; i++) {
      if (_touchCurrent[i].pointerId == event.pointerId) {
        _touchCurrent.splice(i, 1, event);
        break;
      }
    }
  }

  /// Apply a transformation matrix, to the camera and gizmos
  /// @param {Object} transformation Object containing matrices to apply to camera and gizmos
  applyTransformMatrix(transformation) {
    if (transformation['camera'] != null) {
      _m4_1.copy(_cameraMatrixState).premultiply(transformation['camera']);
      _m4_1.decompose(camera.position, camera.quaternion, camera.scale);
      camera.updateMatrix();

      //update camera up vector
      if (_state == State2.rotate || _state == State2.zRotate || _state == State2.animationRotate) {
        camera.up.copy(_upState).applyQuaternion(camera.quaternion);
      }
    }

    if (transformation['gizmos'] != null) {
      _m4_1.copy(_gizmoMatrixState).premultiply(transformation['gizmos']);
      _m4_1.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
      _gizmos.updateMatrix();
    }

    if (_state == State2.scale || _state == State2.focus || _state == State2.animationFocus) {
      _tbRadius = calculateTbRadius(camera);

      if (adjustNearFar) {
        var cameraDistance = camera.position.distanceTo(_gizmos.position);

        var bb = Box3();
        bb.setFromObject(_gizmos);
        var sphere = Sphere();
        bb.getBoundingSphere(sphere);

        var adjustedNearPosition = Math.max(_nearPos0, sphere.radius + sphere.center.length());
        var regularNearPosition = cameraDistance - _initialNear;

        var minNearPos = Math.min(adjustedNearPosition, regularNearPosition);
        camera.near = cameraDistance - minNearPos;

        var adjustedFarPosition = Math.min(_farPos0, -sphere.radius + sphere.center.length());
        var regularFarPosition = cameraDistance - _initialFar;

        var minFarPos = Math.min(adjustedFarPosition, regularFarPosition);
        camera.far = cameraDistance - minFarPos;

        camera.updateProjectionMatrix();
      } else {
        var update = false;

        if (camera.near != _initialNear) {
          camera.near = _initialNear;
          update = true;
        }

        if (camera.far != _initialFar) {
          camera.far = _initialFar;
          update = true;
        }

        if (update) {
          camera.updateProjectionMatrix();
        }
      }
    }
  }

  /// Calculate the angular speed
  /// @param {Number} p0 Position at t0
  /// @param {Number} p1 Position at t1
  /// @param {Number} t0 Initial time in milliseconds
  /// @param {Number} t1 Ending time in milliseconds
  calculateAngularSpeed(p0, p1, t0, t1) {
    var s = p1 - p0;
    var t = (t1 - t0) / 1000;
    if (t == 0) {
      return 0;
    }

    return s / t;
  }

  /// Calculate the distance between two pointers
  /// @param {PointerEvent} p0 The first pointer
  /// @param {PointerEvent} p1 The second pointer
  /// @returns {number} The distance between the two pointers
  calculatePointersDistance(p0, p1) {
    return Math.sqrt(Math.pow(p1.clientX - p0.clientX, 2) + Math.pow(p1.clientY - p0.clientY, 2));
  }

  /// Calculate the rotation axis as the vector perpendicular between two vectors
  /// @param {Vector3} vec1 The first vector
  /// @param {Vector3} vec2 The second vector
  /// @returns {Vector3} The normalized rotation axis
  calculateRotationAxis(vec1, vec2) {
    _rotationMatrix.extractRotation(_cameraMatrixState);
    _quat.setFromRotationMatrix(_rotationMatrix);

    _rotationAxis.crossVectors(vec1, vec2).applyQuaternion(_quat);
    return _rotationAxis.normalize().clone();
  }

  /// Calculate the trackball radius so that gizmo's diamater will be 2/3 of the minimum side of the camera frustum
  /// @param {Camera} camera
  /// @returns {Number} The trackball radius
  calculateTbRadius(Camera camera) {
    var distance = camera.position.distanceTo(_gizmos.position);

    if (camera is PerspectiveCamera) {
      var halfFovV = MathUtils.deg2rad * camera.fov * 0.5; //vertical fov/2 in radians
      var halfFovH = Math.atan((camera.aspect) * Math.tan(halfFovV)); //horizontal fov/2 in radians
      return Math.tan(Math.min(halfFovV, halfFovH)) * distance * radiusFactor;
    } else if (camera is OrthographicCamera) {
      return Math.min(camera.top, camera.right) * radiusFactor;
    }
  }

  /// Focus operation consist of positioning the point of interest in front of the camera and a slightly zoom in
  /// @param {Vector3} point The point of interest
  /// @param {Number} size Scale factor
  /// @param {Number} amount Amount of operation to be completed (used for focus animations, default is complete full operation)
  focus(point, size, [amount = 1]) {
    //move center of camera (along with gizmos) towards point of interest
    _offset.copy(point).sub(_gizmos.position).multiplyScalar(amount);
    _translationMatrix.makeTranslation(_offset.x, _offset.y, _offset.z);

    _gizmoMatrixStateTemp.copy(_gizmoMatrixState);
    _gizmoMatrixState.premultiply(_translationMatrix);
    _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

    _cameraMatrixStateTemp.copy(_cameraMatrixState);
    _cameraMatrixState.premultiply(_translationMatrix);
    _cameraMatrixState.decompose(camera.position, camera.quaternion, camera.scale);

    //apply zoom
    if (enableZoom) {
      applyTransformMatrix(scale(size, _gizmos.position));
    }

    _gizmoMatrixState.copy(_gizmoMatrixStateTemp);
    _cameraMatrixState.copy(_cameraMatrixStateTemp);
  }

  /// Draw a grid and add it to the scene
  drawGrid() {
    if (scene != null) {
      var color = 0x888888;
      var multiplier = 3;
      var size, divisions, maxLength, tick;

      if (camera is OrthographicCamera) {
        var width = camera.right - camera.left;
        var height = camera.bottom - camera.top;

        maxLength = Math.max(width, height);
        tick = maxLength / 20;

        size = maxLength / camera.zoom * multiplier;
        divisions = size / tick * camera.zoom;
      } else if (camera is PerspectiveCamera) {
        var distance = camera.position.distanceTo(_gizmos.position);
        var halfFovV = MathUtils.deg2rad * camera.fov * 0.5;
        var halfFovH = Math.atan((camera.aspect) * Math.tan(halfFovV));

        maxLength = Math.tan(Math.max(halfFovV, halfFovH)) * distance * 2;
        tick = maxLength / 20;

        size = maxLength * multiplier;
        divisions = size / tick;
      }

      if (_grid == null) {
        _grid = GridHelper(size, divisions, color, color);
        _grid.position.copy(_gizmos.position);
        _gridPosition.copy(_grid.position);
        _grid.quaternion.copy(camera.quaternion);
        _grid.rotateX(Math.pi * 0.5);

        scene!.add(_grid);
      }
    }
  }

  /// Remove all listeners, stop animations and clean scene
  dispose() {
    if (_animationId != -1) {
      cancelAnimationFrame(_animationId);
    }

    domElement.removeEventListener('pointerdown', onPointerDown);
    domElement.removeEventListener('pointercancel', onPointerCancel);
    domElement.removeEventListener('wheel', onWheel);
    domElement.removeEventListener('contextmenu', onContextMenu);

    domElement.removeEventListener('pointermove', onPointerMove);
    domElement.removeEventListener('pointerup', onPointerUp);

    domElement.removeEventListener('resize', onWindowResize);

    if (scene != null) scene!.remove(_gizmos);
    disposeGrid();
  }

  /// remove the grid from the scene
  disposeGrid() {
    if (_grid != null && scene != null) {
      scene!.remove(_grid);
      _grid = null;
    }
  }

  /// Compute the easing out cubic function for ease out effect in animation
  /// @param {Number} t The absolute progress of the animation in the bound of 0 (beginning of the) and 1 (ending of animation)
  /// @returns {Number} Result of easing out cubic at time t
  easeOutCubic(t) {
    return 1 - Math.pow(1 - t, 3);
  }

  /// Make rotation gizmos more or less visible
  /// @param {Boolean} isActive If true, make gizmos more visible
  activateGizmos(isActive) {
    var gizmoX = _gizmos.children[0];
    var gizmoY = _gizmos.children[1];
    var gizmoZ = _gizmos.children[2];

    if (isActive) {
      gizmoX.material.setValues({'opacity': 1});
      gizmoY.material.setValues({'opacity': 1});
      gizmoZ.material.setValues({'opacity': 1});
    } else {
      gizmoX.material.setValues({'opacity': 0.6});
      gizmoY.material.setValues({'opacity': 0.6});
      gizmoZ.material.setValues({'opacity': 0.6});
    }
  }

  /// Calculate the cursor position in NDC
  /// @param {number} x Cursor horizontal coordinate within the canvas
  /// @param {number} y Cursor vertical coordinate within the canvas
  /// @param {HTMLElement} canvas The canvas where the renderer draws its output
  /// @returns {Vector2} Cursor normalized position inside the canvas
  getCursorNDC(cursorX, cursorY, canvas) {
    // var canvasRect = canvas.getBoundingClientRect();

    var box = listenableKey.currentContext!.findRenderObject() as RenderBox;
    var canvasRect = box.size;
    var local = box.globalToLocal(Offset(0, 0));

    _v2_1.setX(((cursorX - local.dx) / canvasRect.width) * 2 - 1);
    _v2_1.setY((((local.dy + canvasRect.height) - cursorY) / canvasRect.height) * 2 - 1);
    return _v2_1.clone();
  }

  /// Calculate the cursor position inside the canvas x/y coordinates with the origin being in the center of the canvas
  /// @param {Number} x Cursor horizontal coordinate within the canvas
  /// @param {Number} y Cursor vertical coordinate within the canvas
  /// @param {HTMLElement} canvas The canvas where the renderer draws its output
  /// @returns {Vector2} Cursor position inside the canvas
  getCursorPosition(cursorX, cursorY, canvas) {
    _v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));
    _v2_1.x *= (camera.right - camera.left) * 0.5;
    _v2_1.y *= (camera.top - camera.bottom) * 0.5;
    return _v2_1.clone();
  }

  /// Set the camera to be controlled
  /// @param {Camera} camera The virtual camera to be controlled
  setCamera(externalCamera) {
    camera = externalCamera;

    camera.lookAt(target);
    camera.updateMatrix();

    //setting state
    if (camera.type == 'PerspectiveCamera') {
      _fov0 = camera.fov;
      _fovState = camera.fov;
    }

    _cameraMatrixState0.copy(camera.matrix);
    _cameraMatrixState.copy(_cameraMatrixState0);
    _cameraProjectionState.copy(camera.projectionMatrix);
    _zoom0 = camera.zoom;
    _zoomState = _zoom0;

    _initialNear = camera.near;
    _nearPos0 = camera.position.distanceTo(target) - camera.near;
    _nearPos = _initialNear;

    _initialFar = camera.far;
    _farPos0 = camera.position.distanceTo(target) - camera.far;
    _farPos = _initialFar;

    _up0.copy(camera.up);
    _upState.copy(camera.up);

    camera.updateProjectionMatrix();

    //making gizmos
    _tbRadius = calculateTbRadius(camera);
    makeGizmos(target, _tbRadius);
  }

  /// Set gizmos visibility
  /// @param {Boolean} value Value of gizmos visibility
  setGizmosVisible(value) {
    _gizmos.visible = value;
    dispatchEvent(_changeEvent);
  }

  /// Set gizmos radius factor and redraws gizmos
  /// @param {Float} value Value of radius factor
  setTbRadius(value) {
    radiusFactor = value;
    _tbRadius = calculateTbRadius(camera);

    var curve = EllipseCurve(0, 0, _tbRadius, _tbRadius);
    var points = curve.getPoints(_curvePts);
    var curveGeometry = BufferGeometry().setFromPoints(points);

    for (var gizmo in _gizmos.children) {
      // _gizmos.children[ gizmo ].geometry = curveGeometry;
      gizmo.geometry = curveGeometry;
    }

    dispatchEvent(_changeEvent);
  }

  /// Creates the rotation gizmos matching trackball center and radius
  /// @param {Vector3} tbCenter The trackball center
  /// @param {number} tbRadius The trackball radius
  makeGizmos(tbCenter, tbRadius) {
    var curve = EllipseCurve(0, 0, tbRadius, tbRadius);
    var points = curve.getPoints(_curvePts);

    //geometry
    var curveGeometry = BufferGeometry().setFromPoints(points);

    //material
    var curveMaterialX = LineBasicMaterial({'color': 0xff8080, 'fog': false, 'transparent': true, 'opacity': 0.6});
    var curveMaterialY = LineBasicMaterial({'color': 0x80ff80, 'fog': false, 'transparent': true, 'opacity': 0.6});
    var curveMaterialZ = LineBasicMaterial({'color': 0x8080ff, 'fog': false, 'transparent': true, 'opacity': 0.6});

    //line
    var gizmoX = Line(curveGeometry, curveMaterialX);
    var gizmoY = Line(curveGeometry, curveMaterialY);
    var gizmoZ = Line(curveGeometry, curveMaterialZ);

    var rotation = Math.pi * 0.5;
    gizmoX.rotation.x = rotation;
    gizmoY.rotation.y = rotation;

    //setting state
    _gizmoMatrixState0.identity().setPosition(tbCenter.x, tbCenter.y, tbCenter.z);
    _gizmoMatrixState.copy(_gizmoMatrixState0);

    if (camera.zoom != 1) {
      //adapt gizmos size to camera zoom
      var size = 1 / camera.zoom;
      _scaleMatrix.makeScale(size, size, size);
      _translationMatrix.makeTranslation(-tbCenter.x, -tbCenter.y, -tbCenter.z);

      _gizmoMatrixState.premultiply(_translationMatrix).premultiply(_scaleMatrix);
      _translationMatrix.makeTranslation(tbCenter.x, tbCenter.y, tbCenter.z);
      _gizmoMatrixState.premultiply(_translationMatrix);
    }

    _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

    _gizmos.clear();

    _gizmos.add(gizmoX);
    _gizmos.add(gizmoY);
    _gizmos.add(gizmoZ);
  }

  /// Perform animation for focus operation
  /// @param {Number} time Instant in which this function is called as performance.now()
  /// @param {Vector3} point Point of interest for focus operation
  /// @param {Matrix4} cameraMatrix Camera matrix
  /// @param {Matrix4} gizmoMatrix Gizmos matrix
  onFocusAnim(time, point, cameraMatrix, gizmoMatrix) {
    if (_timeStart == -1) {
      //animation start
      _timeStart = time;
    }

    if (_state == State2.animationFocus) {
      var deltaTime = time - _timeStart;
      var animTime = deltaTime / focusAnimationTime;

      _gizmoMatrixState.copy(gizmoMatrix);

      if (animTime >= 1) {
        //animation end

        _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);

        focus(point, scaleFactor);

        _timeStart = -1;
        updateTbState(State2.idle, false);
        activateGizmos(false);

        dispatchEvent(_changeEvent);
      } else {
        var amount = easeOutCubic(animTime);
        var size = ((1 - amount) + (scaleFactor * amount));

        _gizmoMatrixState.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
        focus(point, size, amount);

        dispatchEvent(_changeEvent);
        var self = this;
        _animationId = requestAnimationFrame((t) {
          self.onFocusAnim(t, point, cameraMatrix, gizmoMatrix.clone());
        });
      }
    } else {
      //interrupt animation

      _animationId = -1;
      _timeStart = -1;
    }
  }

  /// Perform animation for rotation operation
  /// @param {Number} time Instant in which this function is called as performance.now()
  /// @param {Vector3} rotationAxis Rotation axis
  /// @param {number} w0 Initial angular velocity
  onRotationAnim(time, rotationAxis, w0) {
    if (_timeStart == -1) {
      //animation start
      _anglePrev = 0;
      _angleCurrent = 0;
      _timeStart = time;
    }

    if (_state == State2.animationRotate) {
      //w = w0 + alpha * t
      var deltaTime = (time - _timeStart) / 1000;
      var w = w0 + ((-dampingFactor) * deltaTime);

      if (w > 0) {
        //tetha = 0.5 * alpha * t^2 + w0 * t + tetha0
        _angleCurrent = 0.5 * (-dampingFactor) * Math.pow(deltaTime, 2) + w0 * deltaTime + 0;
        applyTransformMatrix(rotate(rotationAxis, _angleCurrent));
        dispatchEvent(_changeEvent);
        var self = this;
        _animationId = requestAnimationFrame((t) {
          self.onRotationAnim(t, rotationAxis, w0);
        });
      } else {
        _animationId = -1;
        _timeStart = -1;

        updateTbState(State2.idle, false);
        activateGizmos(false);

        dispatchEvent(_changeEvent);
      }
    } else {
      //interrupt animation

      _animationId = -1;
      _timeStart = -1;

      if (_state != State2.rotate) {
        activateGizmos(false);
        dispatchEvent(_changeEvent);
      }
    }
  }

  /// Perform pan operation moving camera between two points
  /// @param {Vector3} p0 Initial point
  /// @param {Vector3} p1 Ending point
  /// @param {Boolean} adjust If movement should be adjusted considering camera distance (Perspective only)
  pan(p0, p1, [adjust = false]) {
    var movement = p0.clone().sub(p1);

    if (camera is OrthographicCamera) {
      //adjust movement amount
      movement.multiplyScalar(1 / camera.zoom);
    } else if (camera is PerspectiveCamera && adjust) {
      //adjust movement amount
      _v3_1.setFromMatrixPosition(_cameraMatrixState0); //camera's initial position
      _v3_2.setFromMatrixPosition(_gizmoMatrixState0); //gizmo's initial position
      var distanceFactor = _v3_1.distanceTo(_v3_2) / camera.position.distanceTo(_gizmos.position);
      movement.multiplyScalar(1 / distanceFactor);
    }

    _v3_1.set(movement.x, movement.y, 0).applyQuaternion(camera.quaternion);

    _m4_1.makeTranslation(_v3_1.x, _v3_1.y, _v3_1.z);

    setTransformationMatrices(_m4_1, _m4_1);
    return _transformation;
  }

  /// Reset trackball
  reset() {
    camera.zoom = _zoom0;

    if (camera is PerspectiveCamera) {
      camera.fov = _fov0;
    }

    camera.near = _nearPos;
    camera.far = _farPos;
    _cameraMatrixState.copy(_cameraMatrixState0);
    _cameraMatrixState.decompose(camera.position, camera.quaternion, camera.scale);
    camera.up.copy(_up0);

    camera.updateMatrix();
    camera.updateProjectionMatrix();

    _gizmoMatrixState.copy(_gizmoMatrixState0);
    _gizmoMatrixState0.decompose(_gizmos.position, _gizmos.quaternion, _gizmos.scale);
    _gizmos.updateMatrix();

    _tbRadius = calculateTbRadius(camera);
    makeGizmos(_gizmos.position, _tbRadius);

    camera.lookAt(_gizmos.position);

    updateTbState(State2.idle, false);

    dispatchEvent(_changeEvent);
  }

  /// Rotate the camera around an axis passing by trackball's center
  /// @param {Vector3} axis Rotation axis
  /// @param {number} angle Angle in radians
  /// @returns {Object} Object with 'camera' field containing transformation matrix resulting from the operation to be applied to the camera
  rotate(axis, angle) {
    var point = _gizmos.position; //rotation center
    _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);
    _rotationMatrix.makeRotationAxis(axis, -angle);

    //rotate camera
    _m4_1.makeTranslation(point.x, point.y, point.z);
    _m4_1.multiply(_rotationMatrix);
    _m4_1.multiply(_translationMatrix);

    setTransformationMatrices(_m4_1);

    return _transformation;
  }

  copyState() {
    // var state;
    // if ( camera is OrthographicCamera ) {

    // 	state = JSON.stringify( { 'arcballState': {

    // 		'cameraFar': camera.far,
    // 		'cameraMatrix': camera.matrix,
    // 		'cameraNear': camera.near,
    // 		'cameraUp': camera.up,
    // 		'cameraZoom': camera.zoom,
    // 		'gizmoMatrix': _gizmos.matrix

    // 	} } );

    // } else if ( camera is PerspectiveCamera ) {

    // 	state = JSON.stringify( { 'arcballState': {
    // 		'cameraFar': camera.far,
    // 		'cameraFov': camera.fov,
    // 		'cameraMatrix': camera.matrix,
    // 		'cameraNear': camera.near,
    // 		'cameraUp': camera.up,
    // 		'cameraZoom': camera.zoom,
    // 		'gizmoMatrix': _gizmos.matrix

    // 	} } );

    // }

    // navigator.clipboard.writeText( state );
  }

  pasteState() {
    // var self = this;
    // navigator.clipboard.readText().then( function resolved( value ) {

    // 	self.setStateFromJSON( value );

    // } );
  }

  /// Save the current state of the control. This can later be recover with .reset
  saveState() {
    _cameraMatrixState0.copy(camera.matrix);
    _gizmoMatrixState0.copy(_gizmos.matrix);
    _nearPos = camera.near;
    _farPos = camera.far;
    _zoom0 = camera.zoom;
    _up0.copy(camera.up);

    if (camera is PerspectiveCamera) {
      _fov0 = camera.fov;
    }
  }

  /// Perform uniform scale operation around a given point
  /// @param {Number} size Scale factor
  /// @param {Vector3} point Point around which scale
  /// @param {Boolean} scaleGizmos If gizmos should be scaled (Perspective only)
  /// @returns {Object} Object with 'camera' and 'gizmo' fields containing transformation matrices resulting from the operation to be applied to the camera and gizmos
  scale(size, point, [scaleGizmos = true]) {
    _scalePointTemp.copy(point);
    var sizeInverse = 1 / size;

    if (camera is OrthographicCamera) {
      //camera zoom
      camera.zoom = _zoomState;
      camera.zoom *= size;

      //check min and max zoom
      if (camera.zoom > maxZoom) {
        camera.zoom = maxZoom;
        sizeInverse = _zoomState / maxZoom;
      } else if (camera.zoom < minZoom) {
        camera.zoom = minZoom;
        sizeInverse = _zoomState / minZoom;
      }

      camera.updateProjectionMatrix();

      _v3_1.setFromMatrixPosition(_gizmoMatrixState); //gizmos position

      //scale gizmos so they appear in the same spot having the same dimension
      _scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);
      _translationMatrix.makeTranslation(-_v3_1.x, -_v3_1.y, -_v3_1.z);

      _m4_2.makeTranslation(_v3_1.x, _v3_1.y, _v3_1.z).multiply(_scaleMatrix);
      _m4_2.multiply(_translationMatrix);

      //move camera and gizmos to obtain pinch effect
      _scalePointTemp.sub(_v3_1);

      var amount = _scalePointTemp.clone().multiplyScalar(sizeInverse);
      _scalePointTemp.sub(amount);

      _m4_1.makeTranslation(_scalePointTemp.x, _scalePointTemp.y, _scalePointTemp.z);
      _m4_2.premultiply(_m4_1);

      setTransformationMatrices(_m4_1, _m4_2);
      return _transformation;
    } else if (camera is PerspectiveCamera) {
      _v3_1.setFromMatrixPosition(_cameraMatrixState);
      _v3_2.setFromMatrixPosition(_gizmoMatrixState);

      //move camera
      var distance = _v3_1.distanceTo(_scalePointTemp);
      var amount = distance - (distance * sizeInverse);

      //check min and max distance
      var newDistance = distance - amount;
      if (newDistance < minDistance) {
        sizeInverse = minDistance / distance;
        amount = distance - (distance * sizeInverse);
      } else if (newDistance > maxDistance) {
        sizeInverse = maxDistance / distance;
        amount = distance - (distance * sizeInverse);
      }

      _offset.copy(_scalePointTemp).sub(_v3_1).normalize().multiplyScalar(amount);

      _m4_1.makeTranslation(_offset.x, _offset.y, _offset.z);

      if (scaleGizmos) {
        //scale gizmos so they appear in the same spot having the same dimension
        var pos = _v3_2;

        distance = pos.distanceTo(_scalePointTemp);
        amount = distance - (distance * sizeInverse);
        _offset.copy(_scalePointTemp).sub(_v3_2).normalize().multiplyScalar(amount);

        _translationMatrix.makeTranslation(pos.x, pos.y, pos.z);
        _scaleMatrix.makeScale(sizeInverse, sizeInverse, sizeInverse);

        _m4_2.makeTranslation(_offset.x, _offset.y, _offset.z).multiply(_translationMatrix);
        _m4_2.multiply(_scaleMatrix);

        _translationMatrix.makeTranslation(-pos.x, -pos.y, -pos.z);

        _m4_2.multiply(_translationMatrix);
        setTransformationMatrices(_m4_1, _m4_2);
      } else {
        setTransformationMatrices(_m4_1);
      }

      return _transformation;
    }
  }

  /// Set camera fov
  /// @param {Number} value fov to be setted
  setFov(value) {
    if (camera is PerspectiveCamera) {
      camera.fov = MathUtils.clamp(value, minFov, maxFov);
      camera.updateProjectionMatrix();
    }
  }

  /// Set values in transformation object
  /// @param {Matrix4} camera Transformation to be applied to the camera
  /// @param {Matrix4} gizmos Transformation to be applied to gizmos
  setTransformationMatrices([Matrix4? camera, Matrix4? gizmos]) {
    if (camera != null) {
      if (_transformation['camera'] != null) {
        _transformation['camera']!.copy(camera);
      } else {
        _transformation['camera'] = camera.clone();
      }
    } else {
      _transformation.remove('camera');
    }

    if (gizmos != null) {
      if (_transformation['gizmos'] != null) {
        _transformation['gizmos']!.copy(gizmos);
      } else {
        _transformation['gizmos'] = gizmos.clone();
      }
    } else {
      _transformation.remove('gizmos');
    }
  }

  /// Rotate camera around its direction axis passing by a given point by a given angle
  /// @param {Vector3} point The point where the rotation axis is passing trough
  /// @param {Number} angle Angle in radians
  /// @returns The computed transormation matix
  zRotate(point, angle) {
    _rotationMatrix.makeRotationAxis(_rotationAxis, angle);
    _translationMatrix.makeTranslation(-point.x, -point.y, -point.z);

    _m4_1.makeTranslation(point.x, point.y, point.z);
    _m4_1.multiply(_rotationMatrix);
    _m4_1.multiply(_translationMatrix);

    _v3_1.setFromMatrixPosition(_gizmoMatrixState).sub(point); //vector from rotation center to gizmos position
    _v3_2.copy(_v3_1).applyAxisAngle(_rotationAxis, angle); //apply rotation
    _v3_2.sub(_v3_1);

    _m4_2.makeTranslation(_v3_2.x, _v3_2.y, _v3_2.z);

    setTransformationMatrices(_m4_1, _m4_2);
    return _transformation;
  }

  getRaycaster() {
    return _raycaster;
  }

  /// Unproject the cursor on the 3D object surface
  /// @param {Vector2} cursor Cursor coordinates in NDC
  /// @param {Camera} camera Virtual camera
  /// @returns {Vector3} The point of intersection with the model, if exist, null otherwise
  unprojectOnObj(cursor, camera) {
    var raycaster = getRaycaster();
    raycaster.near = camera.near;
    raycaster.far = camera.far;
    raycaster.setFromCamera(cursor, camera);

    var intersect = raycaster.intersectObjects(scene!.children, true);

    for (var i = 0; i < intersect.length; i++) {
      if (intersect[i].object.uuid != _gizmos.uuid && intersect[i].face != null) {
        return intersect[i].point.clone();
      }
    }

    return null;
  }

  /// Unproject the cursor on the trackball surface
  /// @param {Camera} camera The virtual camera
  /// @param {Number} cursorX Cursor horizontal coordinate on screen
  /// @param {Number} cursorY Cursor vertical coordinate on screen
  /// @param {HTMLElement} canvas The canvas where the renderer draws its output
  /// @param {number} tbRadius The trackball radius
  /// @returns {Vector3} The unprojected point on the trackball surface
  unprojectOnTbSurface(camera, cursorX, cursorY, canvas, tbRadius) {
    if (camera.type == 'OrthographicCamera') {
      _v2_1.copy(getCursorPosition(cursorX, cursorY, canvas));
      _v3_1.set(_v2_1.x, _v2_1.y, 0);

      var x2 = Math.pow(_v2_1.x, 2);
      var y2 = Math.pow(_v2_1.y, 2);
      var r2 = Math.pow(_tbRadius, 2);

      if (x2 + y2 <= r2 * 0.5) {
        //intersection with sphere
        _v3_1.setZ(Math.sqrt(r2 - (x2 + y2)));
      } else {
        //intersection with hyperboloid
        _v3_1.setZ((r2 * 0.5) / (Math.sqrt(x2 + y2)));
      }

      return _v3_1;
    } else if (camera.type == 'PerspectiveCamera') {
      //unproject cursor on the near plane
      _v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));

      _v3_1.set(_v2_1.x, _v2_1.y, -1);
      _v3_1.applyMatrix4(camera.projectionMatrixInverse);

      var rayDir = _v3_1.clone().normalize(); //unprojected ray direction
      var cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);
      var radius2 = Math.pow(tbRadius, 2);

      //	  camera
      //		|\
      //		| \
      //		|  \
      //	h	|	\
      //		| 	 \
      //		| 	  \
      //	_ _ | _ _ _\ _ _  near plane
      //			l

      var h = _v3_1.z;
      var l = Math.sqrt(Math.pow(_v3_1.x, 2) + Math.pow(_v3_1.y, 2));

      if (l == 0) {
        //ray aligned with camera
        rayDir.set(_v3_1.x, _v3_1.y, tbRadius);
        return rayDir;
      }

      var m = h / l;
      var q = cameraGizmoDistance;

      /*
			 * calculate intersection point between unprojected ray and trackball surface
			 *|y = m * x + q
			 *|x^2 + y^2 = r^2
			 *
			 * (m^2 + 1) * x^2 + (2 * m * q) * x + q^2 - r^2 = 0
			 */
      var a = Math.pow(m, 2) + 1;
      var b = 2 * m * q;
      var c = Math.pow(q, 2) - radius2;
      var delta = Math.pow(b, 2) - (4 * a * c);

      if (delta >= 0) {
        //intersection with sphere
        _v2_1.setX((-b - Math.sqrt(delta)) / (2 * a));
        _v2_1.setY(m * _v2_1.x + q);

        var angle = MathUtils.rad2deg * _v2_1.angle();

        if (angle >= 45) {
          //if angle between intersection point and X' axis is >= 45°, return that point
          //otherwise, calculate intersection point with hyperboloid

          var rayLength = Math.sqrt(Math.pow(_v2_1.x, 2) + Math.pow((cameraGizmoDistance - _v2_1.y), 2));
          rayDir.multiplyScalar(rayLength);
          rayDir.z += cameraGizmoDistance;
          return rayDir;
        }
      }

      //intersection with hyperboloid
      /*
			 *|y = m * x + q
			 *|y = (1 / x) * (r^2 / 2)
			 *
			 * m * x^2 + q * x - r^2 / 2 = 0
			 */

      a = m;
      b = q;
      c = -radius2 * 0.5;
      delta = Math.pow(b, 2) - (4 * a * c);
      _v2_1.setX((-b - Math.sqrt(delta)) / (2 * a));
      _v2_1.setY(m * _v2_1.x + q);

      var rayLength = Math.sqrt(Math.pow(_v2_1.x, 2) + Math.pow((cameraGizmoDistance - _v2_1.y), 2));

      rayDir.multiplyScalar(rayLength);
      rayDir.z += cameraGizmoDistance;
      return rayDir;
    }
  }

  /// Unproject the cursor on the plane passing through the center of the trackball orthogonal to the camera
  /// @param {Camera} camera The virtual camera
  /// @param {Number} cursorX Cursor horizontal coordinate on screen
  /// @param {Number} cursorY Cursor vertical coordinate on screen
  /// @param {HTMLElement} canvas The canvas where the renderer draws its output
  /// @param {Boolean} initialDistance If initial distance between camera and gizmos should be used for calculations instead of current (Perspective only)
  /// @returns {Vector3} The unprojected point on the trackball plane
  unprojectOnTbPlane(camera, cursorX, cursorY, canvas, [initialDistance = false]) {
    if (camera.type == 'OrthographicCamera') {
      _v2_1.copy(getCursorPosition(cursorX, cursorY, canvas));
      _v3_1.set(_v2_1.x, _v2_1.y, 0);

      return _v3_1.clone();
    } else if (camera.type == 'PerspectiveCamera') {
      _v2_1.copy(getCursorNDC(cursorX, cursorY, canvas));

      //unproject cursor on the near plane
      _v3_1.set(_v2_1.x, _v2_1.y, -1);
      _v3_1.applyMatrix4(camera.projectionMatrixInverse);

      var rayDir = _v3_1.clone().normalize(); //unprojected ray direction

      //	  camera
      //		|\
      //		| \
      //		|  \
      //	h	|	\
      //		| 	 \
      //		| 	  \
      //	_ _ | _ _ _\ _ _  near plane
      //			l

      var h = _v3_1.z;
      var l = Math.sqrt(Math.pow(_v3_1.x, 2) + Math.pow(_v3_1.y, 2));
      var cameraGizmoDistance;

      if (initialDistance) {
        cameraGizmoDistance = _v3_1
            .setFromMatrixPosition(_cameraMatrixState0)
            .distanceTo(_v3_2.setFromMatrixPosition(_gizmoMatrixState0));
      } else {
        cameraGizmoDistance = camera.position.distanceTo(_gizmos.position);
      }

      /*
			 * calculate intersection point between unprojected ray and the plane
			 *|y = mx + q
			 *|y = 0
			 *
			 * x = -q/m
			*/
      if (l == 0) {
        //ray aligned with camera
        rayDir.set(0, 0, 0);
        return rayDir;
      }

      var m = h / l;
      var q = cameraGizmoDistance;
      var x = -q / m;

      var rayLength = Math.sqrt(Math.pow(q, 2) + Math.pow(x, 2));
      rayDir.multiplyScalar(rayLength);
      rayDir.z = 0;
      return rayDir;
    }
  }

  /// Update camera and gizmos state
  updateMatrixState() {
    //update camera and gizmos state
    _cameraMatrixState.copy(camera.matrix);
    _gizmoMatrixState.copy(_gizmos.matrix);

    if (camera is OrthographicCamera) {
      _cameraProjectionState.copy(camera.projectionMatrix);
      camera.updateProjectionMatrix();
      _zoomState = camera.zoom;
    } else if (camera is PerspectiveCamera) {
      _fovState = camera.fov;
    }
  }

  /// Update the trackball FSA
  /// @param {STATE2} newState New state of the FSA
  /// @param {Boolean} updateMatrices If matriices state should be updated
  updateTbState(newState, updateMatrices) {
    _state = newState;
    if (updateMatrices) {
      updateMatrixState();
    }
  }

  update() {
    var eps = 0.000001;

    if (target.equals(_currentTarget) == false) {
      _gizmos.position.copy(target); //for correct radius calculation
      _tbRadius = calculateTbRadius(camera);
      makeGizmos(target, _tbRadius);
      _currentTarget.copy(target);
    }

    //check min/max parameters
    if (camera is OrthographicCamera) {
      //check zoom
      if (camera.zoom > maxZoom || camera.zoom < minZoom) {
        var newZoom = MathUtils.clamp(camera.zoom, minZoom, maxZoom);
        applyTransformMatrix(scale(newZoom / camera.zoom, _gizmos.position, true));
      }
    } else if (camera is PerspectiveCamera) {
      //check distance
      var distance = camera.position.distanceTo(_gizmos.position);

      if (distance > maxDistance + eps || distance < minDistance - eps) {
        var newDistance = MathUtils.clamp(distance, minDistance, maxDistance);
        applyTransformMatrix(scale(newDistance / distance, _gizmos.position));
        updateMatrixState();
      }

      //check fov
      if (camera.fov < minFov || camera.fov > maxFov) {
        camera.fov = MathUtils.clamp(camera.fov, minFov, maxFov);
        camera.updateProjectionMatrix();
      }

      var oldRadius = _tbRadius;
      _tbRadius = calculateTbRadius(camera);

      if (oldRadius < _tbRadius - eps || oldRadius > _tbRadius + eps) {
        var scale = (_gizmos.scale.x + _gizmos.scale.y + _gizmos.scale.z) / 3;
        var newRadius = _tbRadius / scale;
        var curve = EllipseCurve(0, 0, newRadius, newRadius);
        var points = curve.getPoints(_curvePts);
        var curveGeometry = BufferGeometry().setFromPoints(points);

        for (var gizmo in _gizmos.children) {
          // _gizmos.children[ gizmo ].geometry = curveGeometry;
          gizmo.geometry = curveGeometry;
        }
      }
    }

    camera.lookAt(_gizmos.position);
  }

  setStateFromJSON(json) {
    // var state = JSON.parse( json );

    // if ( state.arcballState != null ) {

    // 	_cameraMatrixState.fromArray( state.arcballState.cameraMatrix.elements );
    // 	_cameraMatrixState.decompose( camera.position, camera.quaternion, camera.scale );

    // 	camera.up.copy( state.arcballState.cameraUp );
    // 	camera.near = state.arcballState.cameraNear;
    // 	camera.far = state.arcballState.cameraFar;

    // 	camera.zoom = state.arcballState.cameraZoom;

    // 	if ( camera is PerspectiveCamera ) {

    // 		camera.fov = state.arcballState.cameraFov;

    // 	}

    // 	_gizmoMatrixState.fromArray( state.arcballState.gizmoMatrix.elements );
    // 	_gizmoMatrixState.decompose( _gizmos.position, _gizmos.quaternion, _gizmos.scale );

    // 	camera.updateMatrix();
    // 	camera.updateProjectionMatrix();

    // 	_gizmos.updateMatrix();

    // 	_tbRadius = calculateTbRadius( camera );
    // 	var gizmoTmp = new Matrix4().copy( _gizmoMatrixState0 );
    // 	makeGizmos( _gizmos.position, _tbRadius );
    // 	_gizmoMatrixState0.copy( gizmoTmp );

    // 	camera.lookAt( _gizmos.position );
    // 	updateTbState( STATE2.IDLE, false );

    // 	dispatchEvent( _changeEvent );

    // }
  }

  cancelAnimationFrame(instance) {}

  requestAnimationFrame(Function callback) {}
}
