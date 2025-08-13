import 'dart:async';
import 'package:flutter/gestures.dart';
import '../models/mouse_event.dart';
import '../models/app_state.dart';

class GestureService {
  static final GestureService _instance = GestureService._internal();
  factory GestureService() => _instance;
  GestureService._internal();

  StreamController<MouseEvent>? _gestureController;
  Stream<MouseEvent> get gestureStream => _gestureController!.stream;

  Timer? _tapTimer;
  DateTime? _lastTapTime;
  int _tapCount = 0;
  Offset? _lastPanPosition;
  bool _isPanning = false;

  // Settings
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  void initialize() {
    _gestureController = StreamController<MouseEvent>.broadcast();
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
  }

  // Handle single finger pan (mouse movement)
  void onPanStart(DragStartDetails details) {
    print('Pan started at: ${details.globalPosition}');
    _lastPanPosition = details.globalPosition;
    _isPanning = true;
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_isPanning && _lastPanPosition != null) {
      final dx = (details.globalPosition.dx - _lastPanPosition!.dx) *
          _settings.mouseSensitivity;
      final dy = (details.globalPosition.dy - _lastPanPosition!.dy) *
          _settings.mouseSensitivity;

      _gestureController!.add(MouseEvent.move(dx, dy));
      print('Pan updated at: ${details.globalPosition}');
      _lastPanPosition = details.globalPosition;
    }
  }

  void onPanEnd(DragEndDetails details) {
    print('Pan ended at: ${details.velocity.pixelsPerSecond}');
    _isPanning = false;
    _lastPanPosition = null;
  }

  // Handle tap gestures
  void onTap() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds <
            _settings.doubleClickThreshold) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    // Wait to see if this is part of a double-tap
    _tapTimer?.cancel();
    _tapTimer = Timer(
        Duration(milliseconds: _settings.doubleClickThreshold.round()), () {
      if (_tapCount == 1) {
        _gestureController!.add(MouseEvent.click('left'));
      } else if (_tapCount >= 2) {
        _gestureController!.add(MouseEvent.gesture('double_click'));
      }
      _tapCount = 0;
    });
  }

  // Handle scale gestures (two finger operations)
  void onScaleStart(ScaleStartDetails details) {
    // Prepare for two-finger gestures
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 2) {
      // Two-finger scroll
      final dy = -details.focalPointDelta.dy * _settings.scrollSensitivity;

      if (dy.abs() > 1.0) {
        final direction = dy > 0 ? 'up' : 'down';
        _gestureController!.add(MouseEvent.gesture('two_finger_scroll',
            data: {'direction': direction, 'amount': dy.abs()}));
      }
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    // Clean up scale gesture
  }

  // Handle long press (right click)
  void onLongPress() {
    _gestureController!.add(MouseEvent.click('right'));
  }

  // Handle force press if available
  void onForcePressStart(ForcePressDetails details) {
    _gestureController!.add(MouseEvent.click('middle'));
  }

  // Custom gesture for two-finger tap (right click alternative)
  void onTwoFingerTap() {
    _gestureController!.add(MouseEvent.click('right'));
  }

  // Scroll wheel simulation
  void simulateScroll(String direction, {double amount = 1.0}) {
    _gestureController!.add(MouseEvent.scroll(direction));
  }

  // Direct button clicks
  void simulateClick(String button) {
    _gestureController!.add(MouseEvent.click(button));
  }

  void dispose() {
    _tapTimer?.cancel();
    _gestureController?.close();
  }
}
