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
  Offset? _lastScalePosition;
  bool _isScaling = false;
  double? _lastScale;

  // Settings
  AppSettings _settings = AppSettings();
  AppSettings get settings => _settings;

  void initialize() {
    _gestureController = StreamController<MouseEvent>.broadcast();
  }

  void updateSettings(AppSettings settings) {
    _settings = settings;
  }

  // Handle single finger pan (mouse movement) - Now handled in scale gestures
  void onPanStart(DragStartDetails details) {
    // This method is kept for compatibility but not used
    // Mouse movement is now handled in onScaleUpdate
  }

  void onPanUpdate(DragUpdateDetails details) {
    // This method is kept for compatibility but not used
    // Mouse movement is now handled in onScaleUpdate
  }

  void onPanEnd(DragEndDetails details) {
    // This method is kept for compatibility but not used
    // Mouse movement is now handled in onScaleEnd
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

  // Handle scale gestures (both single finger movement and multi-finger gestures)
  void onScaleStart(ScaleStartDetails details) {
    _lastScalePosition = details.focalPoint;
    _lastScale = 1.0; // Scale starts at 1.0
    _isScaling = true;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_isScaling && _lastScalePosition != null) {
      // Handle single finger movement (mouse cursor movement)
      if (details.pointerCount == 1) {
        final dx = (details.focalPoint.dx - _lastScalePosition!.dx) *
            _settings.mouseSensitivity;
        final dy = (details.focalPoint.dy - _lastScalePosition!.dy) *
            _settings.mouseSensitivity;

        _gestureController!.add(MouseEvent.move(dx, dy));
      }

      // Handle two-finger gestures
      if (details.pointerCount == 2) {
        // Two-finger scroll (vertical movement)
        // Apply both scroll sensitivity and mouse sensitivity for more responsive scrolling
        var dy = -(details.focalPoint.dy - _lastScalePosition!.dy) *
            _settings.scrollSensitivity *
            _settings.mouseSensitivity;

        // Apply reverse scroll if enabled
        if (_settings.reverseScroll) {
          dy = -dy;
        }

        // Optimize scroll threshold and amount for better responsiveness
        if (dy.abs() > 2.0) {
          // Increased threshold to reduce event frequency
          final direction = dy > 0 ? 'up' : 'down';
          // Normalize amount to a reasonable range (1-10) for consistent feel across platforms
          final normalizedAmount = (dy.abs() / 10).clamp(1.0, 10.0);
          _gestureController!.add(MouseEvent.gesture('two_finger_scroll',
              data: {'direction': direction, 'amount': normalizedAmount}));
        }

        // Pinch zoom detection
        if (_lastScale != null) {
          final scaleDiff = details.scale - _lastScale!;
          if (scaleDiff.abs() > 0.05) {
            // Reduced sensitivity for better control
            _gestureController!.add(MouseEvent.gesture('pinch_zoom',
                data: {'scale': details.scale, 'scaleDiff': scaleDiff}));
          }
        }
        _lastScale = details.scale;

        // Rotation detection
        if (details.rotation.abs() > 0.1) {
          _gestureController!.add(MouseEvent.gesture('rotate',
              data: {'rotation': details.rotation}));
        }
      }

      _lastScalePosition = details.focalPoint;
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    _isScaling = false;
    _lastScalePosition = null;
    _lastScale = null;
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

  // Three-finger gestures
  void onThreeFingerSwipe(String direction) {
    _gestureController!.add(MouseEvent.gesture('three_finger_swipe',
        data: {'direction': direction}));
  }

  void onThreeFingerTap() {
    _gestureController!.add(MouseEvent.click('middle'));
  }

  // Four-finger gestures
  void onFourFingerSwipe(String direction) {
    _gestureController!.add(MouseEvent.gesture('four_finger_swipe',
        data: {'direction': direction}));
  }

  // Scroll wheel simulation
  void simulateScroll(String direction, {double amount = 1.0}) {
    String finalDirection = direction;

    // Apply reverse scroll if enabled
    if (_settings.reverseScroll) {
      finalDirection = direction == 'up' ? 'down' : 'up';
    }

    _gestureController!.add(MouseEvent.scroll(finalDirection));
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
