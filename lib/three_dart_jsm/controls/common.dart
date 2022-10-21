part of jsm_controls;

var _changeEvent = Event({"type": 'change'});
var _startEvent = Event({'type': 'start'});
var _endEvent = Event({'type': 'end'});

var infinity = Math.infinity;

var _euler = Euler(0, 0, 0, 'YXZ');
var _vector = Vector3();

var _lockEvent = Event({'type': 'lock'});
var _unlockEvent = Event({'type': 'unlock'});

var _pi2 = Math.pi / 2;

var _raycaster = Raycaster();

var _plane = Plane();

var _pointer = Vector2();
var _offset = Vector3();
var _intersection = Vector3();
var _worldPosition = Vector3();
var _inverseMatrix = Matrix4();
