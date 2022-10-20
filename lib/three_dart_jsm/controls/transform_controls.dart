part of jsm_controls;

var _tempVector = Vector3();
var _tempVector2 = Vector3();
var _tempQuaternion = Quaternion();
var _unit = {"X": Vector3(1, 0, 0), "Y": Vector3(0, 1, 0), "Z": Vector3(0, 0, 1)};

var _mouseDownEvent = Event({"type": 'mouseDown'});
var _mouseUpEvent = Event({"type": 'mouseUp', "mode": null});
var _objectChangeEvent = Event({"type": 'objectChange'});

Pointer? _pointer0;

class TransformControls extends Object3D {
  bool isTransformControls = true;

  late dynamic domKey;
  dynamic domElement;

  late TransformControlsGizmo _gizmo;
  late TransformControlsPlane _plane;

  dynamic scope;

  Camera? _camera;
  get camera {
    return _camera;
  }

  set camera(value) {
    if (value != _camera) {
      _camera = value;
      _plane.camera = value;
      _gizmo.camera = value;

      scope.dispatchEvent(Event({"type": 'camera-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Object3D? _object;
  get object {
    return _object;
  }

  set object(value) {
    if (value != _object) {
      _object = value;
      _plane.object = value;
      _gizmo.object = value;

      scope.dispatchEvent(Event({"type": 'object-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _enabled = true;
  get enabled {
    return _enabled;
  }

  set enabled(value) {
    if (value != _enabled) {
      _enabled = value;
      _plane.enabled = value;
      _gizmo.enabled = value;

      scope.dispatchEvent(Event({"type": 'enabled-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  String? _axis;
  get axis {
    return _axis;
  }

  set axis(value) {
    if (value != _axis) {
      _axis = value;
      _plane.axis = value;
      _gizmo.axis = value;

      scope.dispatchEvent(Event({"type": 'axis-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  var _mode = "translate";
  get mode {
    return _mode;
  }

  set mode(value) {
    if (value != _mode) {
      _mode = value;
      _plane.mode = value;
      _gizmo.mode = value;

      scope.dispatchEvent(Event({"type": 'mode-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  var _translationSnap;
  get translationSnap {
    return _translationSnap;
  }

  set translationSnap(value) {
    if (value != _translationSnap) {
      _translationSnap = value;

      scope.dispatchEvent(Event({"type": 'translationSnap-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  num? _rotationSnap;
  get rotationSnap {
    return _rotationSnap;
  }

  set rotationSnap(value) {
    if (value != _rotationSnap) {
      _rotationSnap = value;

      scope.dispatchEvent(Event({"type": 'rotationSnap-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  num? _scaleSnap;
  get scaleSnap {
    return _scaleSnap;
  }

  set scaleSnap(value) {
    if (value != _scaleSnap) {
      _scaleSnap = value;

      scope.dispatchEvent(Event({"type": 'scaleSnap-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  var _space = "world";
  get space {
    return _space;
  }

  set space(value) {
    if (value != _space) {
      _space = value;
      _plane.space = value;
      _gizmo.space = value;

      scope.dispatchEvent(Event({"type": 'space-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  var _size = 1;
  get size {
    return _size;
  }

  set size(value) {
    if (value != _size) {
      _size = value;
      _plane.size = value;
      _gizmo.size = value;

      scope.dispatchEvent(Event({"type": 'size-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _dragging = false;
  get dragging {
    return _dragging;
  }

  set dragging(value) {
    if (value != _dragging) {
      _dragging = value;
      _plane.dragging = value;
      _gizmo.dragging = value;

      scope.dispatchEvent(Event({"type": 'dragging-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _showX = true;
  get showX {
    return _showX;
  }

  set showX(value) {
    if (value != _showX) {
      _showX = value;
      _plane.showX = value;
      _gizmo.showX = value;

      scope.dispatchEvent(Event({"type": 'showX-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _showY = true;
  get showY {
    return _showY;
  }

  set showY(value) {
    if (value != _showY) {
      _showY = value;
      _plane.showY = value;
      _gizmo.showY = value;

      scope.dispatchEvent(Event({"type": 'showY-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  bool _showZ = true;
  get showZ {
    return _showZ;
  }

  set showZ(value) {
    if (value != _showZ) {
      _showZ = value;
      _plane.showZ = value;
      _gizmo.showZ = value;

      scope.dispatchEvent(Event({"type": 'showZ-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  // Reusable utility variables

  // var worldPosition = new Vector3();
  // var worldPositionStart = new Vector3();
  // var worldQuaternion = new Quaternion();
  // var worldQuaternionStart = new Quaternion();
  // var cameraPosition = new Vector3();
  // var cameraQuaternion = new Quaternion();
  // var pointStart = new Vector3();
  // var pointEnd = new Vector3();
  // var rotationAxis = new Vector3();
  // var rotationAngle = 0;
  // var eye = new Vector3();

  Vector3 _worldPosition = Vector3();
  get worldPosition {
    return _worldPosition;
  }

  set worldPosition(value) {
    if (value != _worldPosition) {
      _worldPosition = value;
      // _plane.worldPosition = value;
      // _gizmo.worldPosition = value;

      scope.dispatchEvent(Event({"type": 'worldPosition-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _worldPositionStart = Vector3();
  get worldPositionStart {
    return _worldPositionStart;
  }

  set worldPositionStart(value) {
    if (value != _worldPositionStart) {
      _worldPositionStart = value;
      // _plane.worldPositionStart = value;
      // _gizmo.worldPositionStart = value;

      scope.dispatchEvent(Event({"type": 'worldPositionStart-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Quaternion _worldQuaternion = Quaternion();
  get worldQuaternion {
    return _worldQuaternion;
  }

  set worldQuaternion(value) {
    if (value != _worldQuaternion) {
      _worldQuaternion = value;
      // _plane.worldQuaternion = value;
      // _gizmo.worldQuaternion = value;

      scope.dispatchEvent(Event({"type": 'worldQuaternion-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Quaternion _worldQuaternionStart = Quaternion();
  get worldQuaternionStart {
    return _worldQuaternionStart;
  }

  set worldQuaternionStart(value) {
    if (value != _worldQuaternionStart) {
      _worldQuaternionStart = value;
      // _plane.worldQuaternionStart = value;
      // _gizmo.worldQuaternionStart = value;

      scope.dispatchEvent(Event({"type": 'worldQuaternionStart-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _cameraPosition = Vector3();
  get cameraPosition {
    return _cameraPosition;
  }

  set cameraPosition(value) {
    if (value != _cameraPosition) {
      _cameraPosition = value;
      // _plane.cameraPosition = value;
      // _gizmo.cameraPosition = value;

      scope.dispatchEvent(Event({"type": 'cameraPosition-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Quaternion _cameraQuaternion = Quaternion();
  get cameraQuaternion {
    return _cameraQuaternion;
  }

  set cameraQuaternion(value) {
    if (value != _cameraQuaternion) {
      _cameraQuaternion = value;
      // _plane.cameraQuaternion = value;
      // _gizmo.cameraQuaternion = value;

      scope.dispatchEvent(Event({"type": 'cameraQuaternion-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _pointStart = Vector3();
  get pointStart {
    return _pointStart;
  }

  set pointStart(value) {
    if (value != _pointStart) {
      _pointStart = value;
      // _plane.pointStart = value;
      // _gizmo.pointStart = value;

      scope.dispatchEvent(Event({"type": 'pointStart-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _pointEnd = Vector3();
  get pointEnd {
    return _pointEnd;
  }

  set pointEnd(value) {
    if (value != _pointEnd) {
      _pointEnd = value;
      // _plane.pointEnd = value;
      // _gizmo.pointEnd = value;

      scope.dispatchEvent(Event({"type": 'pointEnd-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _rotationAxis = Vector3();
  get rotationAxis {
    return _rotationAxis;
  }

  set rotationAxis(value) {
    if (value != _rotationAxis) {
      _rotationAxis = value;
      // _plane.rotationAxis = value;
      // _gizmo.rotationAxis = value;

      scope.dispatchEvent(Event({"type": 'rotationAxis-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  num _rotationAngle = 0;
  get rotationAngle {
    return _rotationAngle;
  }

  set rotationAngle(value) {
    if (value != _rotationAngle) {
      _rotationAngle = value;
      // _plane.rotationAngle = value;
      // _gizmo.rotationAngle = value;

      scope.dispatchEvent(Event({"type": 'rotationAngle-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  Vector3 _eye = Vector3();
  get eye {
    return _eye;
  }

  set eye(value) {
    if (value != _eye) {
      _eye = value;
      // _plane.eye = value;
      // _gizmo.eye = value;

      scope.dispatchEvent(Event({"type": 'eye-changed', "value": value}));
      scope.dispatchEvent(_changeEvent);
    }
  }

  final _offset = Vector3();
  final _startNorm = Vector3();
  final _endNorm = Vector3();
  final _cameraScale = Vector3();

  final _parentPosition = Vector3();
  final _parentQuaternion = Quaternion();
  final _parentQuaternionInv = Quaternion();
  final _parentScale = Vector3();

  final _worldScaleStart = Vector3();
  final _worldQuaternionInv = Quaternion();
  final _worldScale = Vector3();

  final _positionStart = Vector3();
  final _quaternionStart = Quaternion();
  final _scaleStart = Vector3();

  TransformControls(camera, this.domKey) : super() {
    scope = this;

    this.visible = false;
    domElement = domKey.currentState;
    // this.domElement.style.touchAction = 'none'; // disable touch scroll

    _gizmo = TransformControlsGizmo(this);
    _gizmo.name = "TransformControlsGizmo";

    _plane = TransformControlsPlane(this);
    _plane.name = "TransformControlsPlane";

    this.camera = camera;

    add(_gizmo);
    add(_plane);

    domElement.addEventListener('pointerdown', _onPointerDown, false);
    domElement.addEventListener('pointermove', _onPointerHover, false);
    domElement.addEventListener('pointerup', _onPointerUp, false);
  }

  // updateMatrixWorld  updates key transformation variables
  @override
  updateMatrixWorld([bool force = false]) {
    if (object != null) {
      object.updateMatrixWorld(force);

      if (object.parent == null) {
        print('TransformControls: The attached 3D object must be a part of the scene graph.');
      } else {
        object.parent.matrixWorld.decompose(_parentPosition, _parentQuaternion, _parentScale);
      }

      object.matrixWorld.decompose(worldPosition, worldQuaternion, _worldScale);

      _parentQuaternionInv.copy(_parentQuaternion).invert();
      _worldQuaternionInv.copy(worldQuaternion).invert();
    }

    camera.updateMatrixWorld(force);

    camera.matrixWorld.decompose(cameraPosition, cameraQuaternion, _cameraScale);

    eye.copy(cameraPosition).sub(worldPosition).normalize();

    super.updateMatrixWorld(force);
  }

  pointerHover(Pointer pointer) {
    if (object == null || dragging == true) return;

    _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera);

    var intersect = intersectObjectWithRay(_gizmo.picker[mode], _raycaster, false);

    if (intersect != null && intersect != false) {
      axis = intersect.object.name;
    } else {
      axis = null;
    }
  }

  pointerDown(Pointer pointer) {
    _pointer0 = pointer;

    if (object == null || dragging == true || pointer.button != 1) return;

    if (axis != null) {
      _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera);

      var planeIntersect = intersectObjectWithRay(_plane, _raycaster, true);

      if (planeIntersect != null && planeIntersect != false) {
        object.updateMatrixWorld(false);
        object.parent.updateMatrixWorld(false);

        _positionStart.copy(object.position);
        _quaternionStart.copy(object.quaternion);
        _scaleStart.copy(object.scale);

        object.matrixWorld.decompose(worldPositionStart, worldQuaternionStart, _worldScaleStart);

        pointStart.copy(planeIntersect.point).sub(worldPositionStart);
      }

      dragging = true;
      _mouseDownEvent.mode = mode;
      dispatchEvent(_mouseDownEvent);
    }
  }

  pointerMove(Pointer pointer) {
    // TODO if not when change axis will cause object position change. why???
    if (pointer.x == _pointer0?.x && pointer.y == _pointer0?.y && pointer.button == _pointer0?.button) {
      return;
    }
    _pointer0 = pointer;

    var axis = this.axis;
    var mode = this.mode;
    var object = this.object;
    var space = this.space;

    if (mode == 'scale') {
      space = 'local';
    } else if (axis == 'E' || axis == 'XYZE' || axis == 'XYZ') {
      space = 'world';
    }

    if (object == null || axis == null || dragging == false || pointer.button != 1) return;

    _raycaster.setFromCamera(Vector2(pointer.x, pointer.y), camera);

    var planeIntersect = intersectObjectWithRay(_plane, _raycaster, true);

    if (planeIntersect == null || planeIntersect == false) return;

    pointEnd.copy(planeIntersect.point).sub(worldPositionStart);

    if (mode == 'translate') {
      // Apply translate

      _offset.copy(pointEnd).sub(pointStart);

      if (space == 'local' && axis != 'XYZ') {
        _offset.applyQuaternion(_worldQuaternionInv);
      }

      if (axis.indexOf('X') == -1) _offset.x = 0;
      if (axis.indexOf('Y') == -1) _offset.y = 0;
      if (axis.indexOf('Z') == -1) _offset.z = 0;

      if (space == 'local' && axis != 'XYZ') {
        _offset.applyQuaternion(_quaternionStart).divide(_parentScale);
      } else {
        _offset.applyQuaternion(_parentQuaternionInv).divide(_parentScale);
      }

      object.position.copy(_offset).add(_positionStart);

      // Apply translation snap

      if (translationSnap != null) {
        if (space == 'local') {
          object.position.applyQuaternion(_tempQuaternion.copy(_quaternionStart).invert());

          if (axis.indexOf('X') != -1) {
            object.position.x = Math.round(object.position.x / translationSnap) * translationSnap;
          }

          if (axis.indexOf('Y') != -1) {
            object.position.y = Math.round(object.position.y / translationSnap) * translationSnap;
          }

          if (axis.indexOf('Z') != -1) {
            object.position.z = Math.round(object.position.z / translationSnap) * translationSnap;
          }

          object.position.applyQuaternion(_quaternionStart);
        }

        if (space == 'world') {
          if (object.parent != null) {
            object.position.add(_tempVector.setFromMatrixPosition(object.parent.matrixWorld));
          }

          if (axis.indexOf('X') != -1) {
            object.position.x = Math.round(object.position.x / translationSnap) * translationSnap;
          }

          if (axis.indexOf('Y') != -1) {
            object.position.y = Math.round(object.position.y / translationSnap) * translationSnap;
          }

          if (axis.indexOf('Z') != -1) {
            object.position.z = Math.round(object.position.z / translationSnap) * translationSnap;
          }

          if (object.parent != null) {
            object.position.sub(_tempVector.setFromMatrixPosition(object.parent.matrixWorld));
          }
        }
      }
    } else if (mode == 'scale') {
      if (axis.indexOf('XYZ') != -1) {
        var d = pointEnd.length() / pointStart.length();

        if (pointEnd.dot(pointStart) < 0) d *= -1;

        _tempVector2.set(d, d, d);
      } else {
        _tempVector.copy(pointStart);
        _tempVector2.copy(pointEnd);

        _tempVector.applyQuaternion(_worldQuaternionInv);
        _tempVector2.applyQuaternion(_worldQuaternionInv);

        _tempVector2.divide(_tempVector);

        if (axis.indexOf('X') == -1) {
          _tempVector2.x = 1;
        }

        if (axis.indexOf('Y') == -1) {
          _tempVector2.y = 1;
        }

        if (axis.indexOf('Z') == -1) {
          _tempVector2.z = 1;
        }
      }

      // Apply scale

      object.scale.copy(_scaleStart).multiply(_tempVector2);

      if (scaleSnap != null) {
        if (axis.indexOf('X') != -1) {
          var x = Math.round(object.scale.x / scaleSnap) * scaleSnap;

          object.scale.x = x != 0 ? x : scaleSnap;
        }

        if (axis.indexOf('Y') != -1) {
          var y = Math.round(object.scale.y / scaleSnap) * scaleSnap;

          object.scale.y = y != 0 ? y : scaleSnap;
        }

        if (axis.indexOf('Z') != -1) {
          var z = Math.round(object.scale.z / scaleSnap) * scaleSnap;

          object.scale.z = z != 0 ? z : scaleSnap;
        }
      }
    } else if (mode == 'rotate') {
      _offset.copy(pointEnd).sub(pointStart);

      var rotationSpeed = 20 / worldPosition.distanceTo(_tempVector.setFromMatrixPosition(camera.matrixWorld));

      if (axis == 'E') {
        rotationAxis.copy(eye);
        rotationAngle = pointEnd.angleTo(pointStart);

        _startNorm.copy(pointStart).normalize();
        _endNorm.copy(pointEnd).normalize();

        rotationAngle *= (_endNorm.cross(_startNorm).dot(eye) < 0 ? 1 : -1);
      } else if (axis == 'XYZE') {
        rotationAxis.copy(_offset).cross(eye).normalize();
        rotationAngle = _offset.dot(_tempVector.copy(rotationAxis).cross(eye)) * rotationSpeed;
      } else if (axis == 'X' || axis == 'Y' || axis == 'Z') {
        rotationAxis.copy(_unit[axis]);

        _tempVector.copy(_unit[axis]);

        if (space == 'local') {
          _tempVector.applyQuaternion(worldQuaternion);
        }

        rotationAngle = _offset.dot(_tempVector.cross(eye).normalize()) * rotationSpeed;
      }

      // Apply rotation snap

      if (rotationSnap != null) {
        rotationAngle = Math.round(rotationAngle / rotationSnap) * rotationSnap;
      }

      // Apply rotate
      if (space == 'local' && axis != 'E' && axis != 'XYZE') {
        object.quaternion.copy(_quaternionStart);
        object.quaternion.multiply(_tempQuaternion.setFromAxisAngle(rotationAxis, rotationAngle)).normalize();
      } else {
        rotationAxis.applyQuaternion(_parentQuaternionInv);
        object.quaternion.copy(_tempQuaternion.setFromAxisAngle(rotationAxis, rotationAngle));
        object.quaternion.multiply(_quaternionStart).normalize();
      }
    }

    dispatchEvent(_changeEvent);
    dispatchEvent(_objectChangeEvent);
  }

  pointerUp(Pointer pointer) {
    if (pointer.button != 0) return;

    if (dragging && (axis != null)) {
      _mouseUpEvent.mode = mode;
      dispatchEvent(_mouseUpEvent);
    }

    dragging = false;
    axis = null;
  }

  @override
  dispose() {
    domElement.removeEventListener('pointerdown', _onPointerDown);
    domElement.removeEventListener('pointermove', _onPointerHover);
    domElement.removeEventListener('pointermove', _onPointerMove);
    domElement.removeEventListener('pointerup', _onPointerUp);

    traverse((child) {
      if (child.geometry) child.geometry.dispose();
      if (child.material) child.material.dispose();
    });
  }

  // Set current object
  @override
  attach(object) {
    this.object = object;
    this.visible = true;

    return this;
  }

  // Detatch from object
  detach() {
    object = null;
    this.visible = false;
    axis = null;

    return this;
  }

  getRaycaster() {
    return _raycaster;
  }

  // TODO: deprecate

  getMode() {
    return mode;
  }

  setMode(mode) {
    this.mode = mode;
  }

  setTranslationSnap(translationSnap) {
    this.translationSnap = translationSnap;
  }

  setRotationSnap(rotationSnap) {
    this.rotationSnap = rotationSnap;
  }

  setScaleSnap(scaleSnap) {
    this.scaleSnap = scaleSnap;
  }

  setSize(size) {
    this.size = size;
  }

  setSpace(space) {
    this.space = space;
  }

  update() {
    print('THREE.TransformControls: update function has no more functionality and therefore has been deprecated.');
  }

  // mouse / touch event handlers
  _getPointer(event) {
    return getPointer(event);
  }

  _onPointerDown(event) {
    return onPointerDown(event);
  }

  _onPointerHover(event) {
    return onPointerHover(event);
  }

  _onPointerMove(event) {
    return onPointerMove(event);
  }

  _onPointerUp(event) {
    return onPointerUp(event);
  }

  getPointer(event) {
    final RenderBox renderBox = domKey.currentContext!.findRenderObject();
    final size = renderBox.size;
    var rect = size;
    int left = 0;
    int top = 0;

    var x = (event.clientX - left) / rect.width * 2 - 1;
    var y = -(event.clientY - top) / rect.height * 2 + 1;
    var button = event.button;

    return Pointer(x, y, button);
  }

  onPointerHover(event) {
    if (!enabled) return;

    switch (event.pointerType) {
      case 'mouse':
      case 'pen':
        pointerHover(_getPointer(event));
        break;
    }
  }

  onPointerDown(event) {
    if (!enabled) return;

    // this.domElement.setPointerCapture( event.pointerId );

    domElement.addEventListener('pointermove', _onPointerMove);

    pointerHover(_getPointer(event));
    pointerDown(_getPointer(event));
  }

  onPointerMove(event) {
    if (!enabled) return;

    pointerMove(_getPointer(event));
  }

  onPointerUp(event) {
    if (!enabled) return;

    // this.domElement.releasePointerCapture( event.pointerId );

    domElement.removeEventListener('pointermove', _onPointerMove);

    pointerUp(_getPointer(event));
  }

  intersectObjectWithRay(object, raycaster, includeInvisible) {
    var allIntersections = raycaster.intersectObject(object, true, null);

    for (var i = 0; i < allIntersections.length; i++) {
      if (allIntersections[i].object.visible || includeInvisible) {
        return allIntersections[i];
      }
    }

    return false;
  }
}

class Pointer {
  late double x;
  late double y;
  late int button;
  Pointer(this.x, this.y, this.button);

  toJSON() {
    return {"x": x, "y": y, "button": button};
  }
}
