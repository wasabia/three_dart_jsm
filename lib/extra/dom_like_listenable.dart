import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class DomLikeListenable extends StatefulWidget {
  WidgetBuilder builder;

  DomLikeListenable({Key? key, required this.builder}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DomLikeListenableState();
  }
}

class DomLikeListenableState extends State<DomLikeListenable> {
  Map<String, List<Function>> _listeners = {};

  double? _clientWidth;
  double? _clientHeight;

  double get clientWidth => _clientWidth!;
  double get clientHeight => _clientHeight!;

  dynamic pointerLockElement;

  @override
  void initState() {
    super.initState();
  }
  
  void removeAllListeners() {
    _listeners.clear();
  }

  void addEventListener(String name, Function callback, [bool flag = false]) {
    var _cls = _listeners[name] ?? [];
    _cls.add(callback);
    _listeners[name] = _cls;
  }

  void removeEventListener(String name, Function callback, [bool flag = false]) {
    var _cls = _listeners[name] ?? [];
    _cls.remove(callback);
    _listeners[name] = _cls;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance?.addPostFrameCallback((t) {
      if (_clientWidth == null || _clientHeight == null) {
        RenderBox getBox = context.findRenderObject() as RenderBox;
        _clientWidth = getBox.size.width;
        _clientHeight = getBox.size.height;
      }
    });

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          _onWheel(context, pointerSignal);
        }
      },
      onPointerDown: (PointerDownEvent event) {
        _onPointerDown(context, event);
      },
      onPointerMove: (PointerMoveEvent event) {
        _onPointerMove(context, event);
      },
      onPointerUp: (PointerUpEvent event) {
        _onPointerUp(context, event);
      },
      onPointerCancel: (PointerCancelEvent event) {
        _onPointerCancel(context, event);
      },
      child: widget.builder(context),
    );
  }

  void _onWheel(BuildContext context, PointerScrollEvent event) {
    var wpe = WebPointerEvent.fromPointerScrollEvent(context, event);

    emit("wheel", wpe);
  }

  void _onPointerDown(BuildContext context, PointerDownEvent event) {
    var wpe = WebPointerEvent.fromPointerDownEvent(context, event);

    emit("touchstart", wpe);
    emit("pointerdown", wpe);
  }

  void _onPointerMove(BuildContext context, PointerMoveEvent event) {
    var wpe = WebPointerEvent.fromPointerMoveEvent(context, event);

    emit("touchmove", wpe);
    emit("pointermove", wpe);
  }

  void _onPointerUp(BuildContext context, PointerUpEvent event) {
    var wpe = WebPointerEvent.fromPointerUpEvent(context, event);
    emit("touchend", wpe);
    emit("pointerup", wpe);
  }

  void _onPointerCancel(BuildContext context, PointerCancelEvent event) {
    // emit("pointercancel", event);
  }

  void emit(String name, event) {
    var _callbacks = _listeners[name];
    if (_callbacks != null && _callbacks.length > 0) {
      var _len = _callbacks.length;
      for (int i = 0; i < _len; i++) {
        var _cb = _callbacks[i];
        _cb(event);
      }
    }
  }

  void setPointerCapture(int pointerId) {
    // TODO
  }

  void releasePointerCapture(int pointerId) {
    // TODO
  }

  void requestPointerLock() {
    // TODO
  }

  void exitPointerLock() {
    // TODO
  }
}

class WebPointerEvent {
  late int pointerId;
  late int button;
  String pointerType = 'touch';
  late double clientX;
  late double clientY;
  late double pageX;
  late double pageY;

  bool ctrlKey = false;
  bool metaKey = false;
  bool shiftKey = false;
  bool isPrimary = true;

  int deltaMode = 0;
  double deltaY = 0.0;
  double deltaX = 0.0;

  WebPointerEvent() {}

  static String getPointerType(event) {
    return event.kind == PointerDeviceKind.touch ? 'touch' : 'mouse';
  }

  static int getButton(event) {
    if (event.kind == PointerDeviceKind.touch) {
      return event.buttons == 0x01 ? 1 : 0;
    } else {
      return event.buttons == 2
          ? 2
          : event.buttons == 0x01
              ? 0
              : 1;
    }
  }

  static WebPointerEvent convertEvent(context, event) {
    var wpe = WebPointerEvent();

    wpe.pointerId = event.pointer;
    wpe.pointerType = getPointerType(event);
    wpe.button = getButton(event);

    RenderBox getBox = context.findRenderObject() as RenderBox;
    var local = getBox.globalToLocal(event.position);
    wpe.clientX = local.dx;
    wpe.clientY = local.dy;
    wpe.pageX = event.position.dx;
    wpe.pageY = event.position.dy;

    if (event is PointerScrollEvent) {
      wpe.deltaX = event.scrollDelta.dx;
      wpe.deltaY = event.scrollDelta.dy;
    }

    return wpe;
  }

  factory WebPointerEvent.fromPointerScrollEvent(
      BuildContext context, PointerScrollEvent event) {
    return convertEvent(context, event);
  }

  factory WebPointerEvent.fromPointerDownEvent(
      BuildContext context, PointerDownEvent event) {
    return convertEvent(context, event);
  }

  factory WebPointerEvent.fromPointerMoveEvent(
      BuildContext context, PointerMoveEvent event) {
    return convertEvent(context, event);
  }

  factory WebPointerEvent.fromPointerUpEvent(
      BuildContext context, PointerUpEvent event) {
    return convertEvent(context, event);
  }

  preventDefault() {
    // TODO
  }

  String toString() {
    return "pointerId: ${pointerId} button: ${button} pointerType: ${pointerType} clientX: ${clientX} clientY: ${clientY} pageX: ${pageX} pageY: ${pageY} ";
  }
}
