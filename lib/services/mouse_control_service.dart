import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Win32 POINT structure
final class POINT extends Struct {
  @Int32()
  external int x;
  
  @Int32()
  external int y;
}

abstract class MouseController {
  void moveMouse(double dx, double dy);
  void click(String button);
  void scroll(String direction, {double amount = 1.0});
  void handleGesture(String gestureType, {Map<String, dynamic>? data});
  void handleKeyboard(String action, {String? text, String? key});
  void dispose();
}

class MouseControllerFactory {
  static MouseController create() {
    if (Platform.isWindows) {
      return WindowsMouseController();
    } else if (Platform.isLinux) {
      return LinuxMouseController();
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
}

// Windows implementation using FFI for direct Win32 API calls
class WindowsMouseController implements MouseController {
  late final DynamicLibrary _user32;
  late final int Function(int, int) _setCursorPos;
  late final int Function(Pointer<POINT>) _getCursorPos;
  late final void Function(int, int, int, int, int) _mouseEvent;

  WindowsMouseController() {
    try {
      _user32 = DynamicLibrary.open('user32.dll');
      _setCursorPos = _user32.lookupFunction<
          Int32 Function(Int32, Int32),
          int Function(int, int)>('SetCursorPos');
      _getCursorPos = _user32.lookupFunction<
          Int32 Function(Pointer<POINT>),
          int Function(Pointer<POINT>)>('GetCursorPos');
      _mouseEvent = _user32.lookupFunction<
          Void Function(Uint32, Uint32, Uint32, Uint32, Uint32),
          void Function(int, int, int, int, int)>('mouse_event');
      print('Windows FFI mouse controller initialized');
    } catch (e) {
      print('FFI initialization failed, falling back to PowerShell: $e');
      _initializePowerShell();
    }
  }

  bool _usePowerShell = false;

  void _initializePowerShell() {
    _usePowerShell = true;
    print('Windows PowerShell mouse controller initialized');
  }

  @override
  void moveMouse(double dx, double dy) {
    if (_usePowerShell) {
      _moveMousePowerShell(dx, dy);
      return;
    }

    try {
      final point = calloc<POINT>();
      _getCursorPos(point);
      final newX = point.ref.x + dx.round();
      final newY = point.ref.y + dy.round();
      _setCursorPos(newX, newY);
      calloc.free(point);
    } catch (e) {
      print('FFI mouse move error, falling back to PowerShell: $e');
      _usePowerShell = true;
      _moveMousePowerShell(dx, dy);
    }
  }

  void _moveMousePowerShell(double dx, double dy) {
    try {
      final deltaX = dx.round();
      final deltaY = dy.round();
      
      final script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseHelper {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT {
        public int X;
        public int Y;
    }
    
    public static void MoveMouse(int deltaX, int deltaY) {
        POINT current;
        GetCursorPos(out current);
        SetCursorPos(current.X + deltaX, current.Y + deltaY);
    }
}
"@

[MouseHelper]::MoveMouse($deltaX, $deltaY)
      ''';

      Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
    } catch (e) {
      print('Windows mouse move error: $e');
    }
  }

  @override
  void click(String button) {
    if (_usePowerShell) {
      _clickPowerShell(button);
      return;
    }

    try {
      final leftDown = button.toLowerCase() == 'left' ? 0x0002 : (button.toLowerCase() == 'right' ? 0x0008 : 0x0020);
      final leftUp = button.toLowerCase() == 'left' ? 0x0004 : (button.toLowerCase() == 'right' ? 0x0010 : 0x0040);
      
      _mouseEvent(leftDown, 0, 0, 0, 0);
      _mouseEvent(leftUp, 0, 0, 0, 0);
    } catch (e) {
      print('FFI mouse click error, falling back to PowerShell: $e');
      _usePowerShell = true;
      _clickPowerShell(button);
    }
  }

  void _clickPowerShell(String button) {
    try {
      final leftDown = button.toLowerCase() == 'left' ? 0x0002 : (button.toLowerCase() == 'right' ? 0x0008 : 0x0020);
      final leftUp = button.toLowerCase() == 'left' ? 0x0004 : (button.toLowerCase() == 'right' ? 0x0010 : 0x0040);
      
      final script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseClicker {
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
    
    public static void Click(int downFlag, int upFlag) {
        mouse_event(downFlag, 0, 0, 0, 0);
        mouse_event(upFlag, 0, 0, 0, 0);
    }
}
"@

[MouseClicker]::Click($leftDown, $leftUp)
      ''';

      Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
    } catch (e) {
      print('Windows mouse click error: $e');
    }
  }

  @override
  void scroll(String direction, {double amount = 1.0}) {
    if (_usePowerShell) {
      _scrollPowerShell(direction, amount: amount);
      return;
    }

    try {
      if (direction == 'left' || direction == 'right') {
        // Horizontal scrolling
        final delta = direction == 'right' ? (120 * amount).round() : (-120 * amount).round();
        _mouseEvent(0x1000, 0, 0, delta, 0); // MOUSEEVENTF_HWHEEL = 0x1000
      } else {
        // Vertical scrolling - Fixed: Windows scroll delta should be positive for up, negative for down
        final delta = direction == 'up' ? (120 * amount).round() : (-120 * amount).round();
        _mouseEvent(0x0800, 0, 0, delta, 0); // MOUSEEVENTF_WHEEL = 0x0800
      }
    } catch (e) {
      print('FFI mouse scroll error, falling back to PowerShell: $e');
      _usePowerShell = true;
      _scrollPowerShell(direction, amount: amount);
    }
  }

  void _scrollPowerShell(String direction, {double amount = 1.0}) {
    try {
      final script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MouseScroller {
    [DllImport("user32.dll")]
    public static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
    
    public static void ScrollVertical(int delta) {
        mouse_event(0x0800, 0, 0, delta, 0); // MOUSEEVENTF_WHEEL
    }
    
    public static void ScrollHorizontal(int delta) {
        mouse_event(0x1000, 0, 0, delta, 0); // MOUSEEVENTF_HWHEEL
    }
}
"@

''';

      if (direction == 'left' || direction == 'right') {
        // Horizontal scrolling
        final delta = direction == 'right' ? (120 * amount).round() : (-120 * amount).round();
        final fullScript = script + '[MouseScroller]::ScrollHorizontal($delta)';
        Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', fullScript]);
      } else {
        // Vertical scrolling - Fixed: positive for up, negative for down
        final delta = direction == 'up' ? (120 * amount).round() : (-120 * amount).round();
        final fullScript = script + '[MouseScroller]::ScrollVertical($delta)';
        Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', fullScript]);
      }
    } catch (e) {
      print('Windows mouse scroll error: $e');
    }
  }

  String _getClickFlag(String button) {
    switch (button.toLowerCase()) {
      case 'left':
        return 'LeftDown, LeftUp';
      case 'right':
        return 'RightDown, RightUp';
      case 'middle':
        return 'MiddleDown, MiddleUp';
      default:
        return 'LeftDown, LeftUp';
    }
  }

  @override
  void handleGesture(String gestureType, {Map<String, dynamic>? data}) {
    try {
      switch (gestureType) {
        case 'double_click':
          _performDoubleClick();
          break;
        case 'two_finger_scroll':
          _handleTwoFingerScroll(data);
          break;
        case 'three_finger_swipe':
          _handleThreeFingerSwipe(data);
          break;
        case 'four_finger_swipe':
          _handleFourFingerSwipe(data);
          break;
        case 'pinch_zoom':
          _handlePinchZoom(data);
          break;
        case 'rotate':
          _handleRotate(data);
          break;
        default:
          print('Unsupported gesture: $gestureType');
      }
    } catch (e) {
      print('Windows gesture handling error: $e');
    }
  }

  @override
  void handleKeyboard(String action, {String? text, String? key}) {
    try {
      switch (action) {
        case 'type':
          if (text != null) {
            _typeText(text);
          }
          break;
        case 'key':
          if (key != null) {
            _pressKey(key);
          }
          break;
        case 'backspace':
          _pressKey('BackSpace');
          break;
        case 'enter':
          _pressKey('Return');
          break;
        case 'space':
          _pressKey('space');
          break;
        case 'tab':
          _pressKey('Tab');
          break;
        case 'escape':
          _pressKey('Escape');
          break;
        default:
          print('Unsupported keyboard action: $action');
      }
    } catch (e) {
      print('Windows keyboard handling error: $e');
    }
  }

  void _typeText(String text) {
    if (_usePowerShell) {
      _typeTextPowerShell(text);
      return;
    }

    try {
      // For FFI implementation, we'll fall back to PowerShell for now
      // as typing text requires more complex Win32 API calls
      _typeTextPowerShell(text);
    } catch (e) {
      print('FFI text typing error: $e');
      _typeTextPowerShell(text);
    }
  }

  void _typeTextPowerShell(String text) {
    try {
      // Escape special characters for PowerShell
      final escapedText = text
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('\$', '\\\$')
          .replaceAll('`', '\\`');

      final script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class KeyboardHelper {
    public static void TypeText(string text) {
        SendKeys.SendWait(text);
    }
}
"@

[KeyboardHelper]::TypeText("$escapedText")
      ''';

      Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
    } catch (e) {
      print('Windows text typing error: $e');
    }
  }

  void _pressKey(String key) {
    if (_usePowerShell) {
      _pressKeyPowerShell(key);
      return;
    }

    try {
      // For FFI implementation, we'll fall back to PowerShell for now
      _pressKeyPowerShell(key);
    } catch (e) {
      print('FFI key press error: $e');
      _pressKeyPowerShell(key);
    }
  }

  void _pressKeyPowerShell(String key) {
    try {
      // Map common keys to SendKeys format
      String sendKeysFormat = _mapKeyToSendKeys(key);
      
      final script = '''
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class KeyboardHelper {
    public static void PressKey(string key) {
        SendKeys.SendWait(key);
    }
}
"@

[KeyboardHelper]::PressKey("$sendKeysFormat")
      ''';

      Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
    } catch (e) {
      print('Windows key press error: $e');
    }
  }

  String _mapKeyToSendKeys(String key) {
    switch (key.toLowerCase()) {
      case 'backspace':
        return '{BACKSPACE}';
      case 'return':
      case 'enter':
        return '{ENTER}';
      case 'space':
        return ' ';
      case 'tab':
        return '{TAB}';
      case 'escape':
        return '{ESC}';
      case 'delete':
        return '{DELETE}';
      case 'home':
        return '{HOME}';
      case 'end':
        return '{END}';
      case 'pageup':
        return '{PGUP}';
      case 'pagedown':
        return '{PGDN}';
      case 'up':
        return '{UP}';
      case 'down':
        return '{DOWN}';
      case 'left':
        return '{LEFT}';
      case 'right':
        return '{RIGHT}';
      case 'f1':
        return '{F1}';
      case 'f2':
        return '{F2}';
      case 'f3':
        return '{F3}';
      case 'f4':
        return '{F4}';
      case 'f5':
        return '{F5}';
      case 'f6':
        return '{F6}';
      case 'f7':
        return '{F7}';
      case 'f8':
        return '{F8}';
      case 'f9':
        return '{F9}';
      case 'f10':
        return '{F10}';
      case 'f11':
        return '{F11}';
      case 'f12':
        return '{F12}';
      default:
        return key;
    }
  }

  void _performDoubleClick() {
    // Perform two quick left clicks
    click('left');
    Future.delayed(const Duration(milliseconds: 50), () => click('left'));
  }

  void _handleTwoFingerScroll(Map<String, dynamic>? data) {
    if (data != null) {
      final direction = data['direction'] as String? ?? 'up';
      final amount = data['amount'] as double? ?? 1.0;
      scroll(direction, amount: amount);
    }
  }

  void _handleThreeFingerSwipe(Map<String, dynamic>? data) {
    if (data != null) {
      final direction = data['direction'] as String? ?? 'left';
      _performWindowsSwipeGesture(direction);
    }
  }

  void _handleFourFingerSwipe(Map<String, dynamic>? data) {
    if (data != null) {
      final direction = data['direction'] as String? ?? 'left';
      _performWindowsFourFingerSwipe(direction);
    }
  }

  void _handlePinchZoom(Map<String, dynamic>? data) {
    if (data != null) {
      final scale = data['scale'] as double? ?? 1.0;
      final isZoomIn = scale > 1.0;

      // Simulate Ctrl + Mouse Wheel for zoom
      final script = '''
        Add-Type @"
          using System;
          using System.Runtime.InteropServices;
          using System.Windows.Forms;
          public class KeyboardOperations {
            [DllImport("user32.dll")]
            private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
            [DllImport("user32.dll")]
            private static extern void mouse_event(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
            
            public static void SimulateCtrlMouseWheel(bool zoomIn) {
              // Press Ctrl
              keybd_event(0x11, 0, 0, 0);
              // Mouse wheel
              int delta = zoomIn ? 120 : -120;
              mouse_event(0x0800, 0, 0, delta, 0);
              // Release Ctrl
              keybd_event(0x11, 0, 0x0002, 0);
            }
          }
"@
        [KeyboardOperations]::SimulateCtrlMouseWheel(\$$isZoomIn)
      ''';

      Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
    }
  }

  void _handleRotate(Map<String, dynamic>? data) {
    // Rotation gestures could be mapped to specific application shortcuts
    print('Rotation gesture received: $data');
  }

  void _performWindowsSwipeGesture(String direction) {
    // Map three-finger swipes to common Windows gestures
    final script = '''
      Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class KeyboardOperations {
          [DllImport("user32.dll")]
          private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
          
          public static void SimulateSwipe(string direction) {
            switch (direction) {
              case "left":
                // Alt + Left (Browser back)
                keybd_event(0x12, 0, 0, 0); // Alt down
                keybd_event(0x25, 0, 0, 0); // Left down
                keybd_event(0x25, 0, 0x0002, 0); // Left up
                keybd_event(0x12, 0, 0x0002, 0); // Alt up
                break;
              case "right":
                // Alt + Right (Browser forward)
                keybd_event(0x12, 0, 0, 0); // Alt down
                keybd_event(0x27, 0, 0, 0); // Right down
                keybd_event(0x27, 0, 0x0002, 0); // Right up
                keybd_event(0x12, 0, 0x0002, 0); // Alt up
                break;
              case "up":
                // Win + Tab (Task view)
                keybd_event(0x5B, 0, 0, 0); // Win down
                keybd_event(0x09, 0, 0, 0); // Tab down
                keybd_event(0x09, 0, 0x0002, 0); // Tab up
                keybd_event(0x5B, 0, 0x0002, 0); // Win up
                break;
              case "down":
                // Win + D (Show desktop)
                keybd_event(0x5B, 0, 0, 0); // Win down
                keybd_event(0x44, 0, 0, 0); // D down
                keybd_event(0x44, 0, 0x0002, 0); // D up
                keybd_event(0x5B, 0, 0x0002, 0); // Win up
                break;
            }
          }
        }
"@
      [KeyboardOperations]::SimulateSwipe("$direction")
    ''';

    Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
  }

  void _performWindowsFourFingerSwipe(String direction) {
    // Map four-finger swipes to Windows virtual desktop gestures
    final script = '''
      Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class KeyboardOperations {
          [DllImport("user32.dll")]
          private static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);
          
          public static void SimulateFourFingerSwipe(string direction) {
            switch (direction) {
              case "left":
                // Ctrl + Win + Left (Switch to left virtual desktop)
                keybd_event(0x11, 0, 0, 0); // Ctrl down
                keybd_event(0x5B, 0, 0, 0); // Win down
                keybd_event(0x25, 0, 0, 0); // Left down
                keybd_event(0x25, 0, 0x0002, 0); // Left up
                keybd_event(0x5B, 0, 0x0002, 0); // Win up
                keybd_event(0x11, 0, 0x0002, 0); // Ctrl up
                break;
              case "right":
                // Ctrl + Win + Right (Switch to right virtual desktop)
                keybd_event(0x11, 0, 0, 0); // Ctrl down
                keybd_event(0x5B, 0, 0, 0); // Win down
                keybd_event(0x27, 0, 0, 0); // Right down
                keybd_event(0x27, 0, 0x0002, 0); // Right up
                keybd_event(0x5B, 0, 0x0002, 0); // Win up
                keybd_event(0x11, 0, 0x0002, 0); // Ctrl up
                break;
              case "up":
                // Win + Ctrl + D (Create new virtual desktop)
                keybd_event(0x5B, 0, 0, 0); // Win down
                keybd_event(0x11, 0, 0, 0); // Ctrl down
                keybd_event(0x44, 0, 0, 0); // D down
                keybd_event(0x44, 0, 0x0002, 0); // D up
                keybd_event(0x11, 0, 0x0002, 0); // Ctrl up
                keybd_event(0x5B, 0, 0x0002, 0); // Win up
                break;
              case "down":
                // Win + Ctrl + F4 (Close current virtual desktop)
                keybd_event(0x5B, 0, 0, 0); // Win down
                keybd_event(0x11, 0, 0, 0); // Ctrl down
                keybd_event(0x73, 0, 0, 0); // F4 down
                keybd_event(0x73, 0, 0x0002, 0); // F4 up
                keybd_event(0x11, 0, 0x0002, 0); // Ctrl up
                keybd_event(0x5B, 0, 0x0002, 0); // Win up
                break;
            }
          }
        }
"@
      [KeyboardOperations]::SimulateFourFingerSwipe("$direction")
    ''';

    Process.runSync('powershell', ['-ExecutionPolicy', 'Bypass', '-Command', script]);
  }

  @override
  void dispose() {
    // Clean up resources if needed
  }
}

// Linux implementation using command line tools
class LinuxMouseController implements MouseController {
  bool _hasXdotool = false;

  LinuxMouseController() {
    _checkDependencies();
  }

  void _checkDependencies() {
    try {
      final result = Process.runSync('which', ['xdotool']);
      _hasXdotool = result.exitCode == 0;
      print(
          'Linux mouse controller initialized - xdotool available: $_hasXdotool');
    } catch (e) {
      print('Error checking xdotool: $e');
    }
  }

  @override
  void moveMouse(double dx, double dy) {
    if (!_hasXdotool) {
      print('xdotool not available for mouse movement');
      return;
    }

    try {
      Process.runSync('xdotool',
          ['mousemove_relative', '--', dx.toString(), dy.toString()]);
    } catch (e) {
      print('Linux mouse move error: $e');
    }
  }

  @override
  void click(String button) {
    if (!_hasXdotool) {
      print('xdotool not available for mouse clicks');
      return;
    }
    print('Linux click: $button');

    try {
      final buttonNum = _getButtonNumber(button);
      Process.runSync('xdotool', ['click', buttonNum]);
    } catch (e) {
      print('Linux mouse click error: $e');
    }
  }

  @override
  void scroll(String direction, {double amount = 1.0}) {
    if (!_hasXdotool) {
      print('xdotool not available for mouse scroll');
      return;
    }

    try {
      // Use xdotool's more efficient approach - execute as a single command
      // Map amount to reasonable scroll steps (1-5 steps max for responsiveness)
      final steps = (amount / 2).round().clamp(1, 5);
      
      // Map direction to button numbers
      // Vertical: up=4, down=5  Horizontal: left=6, right=7
      String buttonNum;
      switch (direction) {
        case 'up':
          buttonNum = '4';
          break;
        case 'down':
          buttonNum = '5';
          break;
        case 'left':
          buttonNum = '6';
          break;
        case 'right':
          buttonNum = '7';
          break;
        default:
          buttonNum = '5'; // default to down if unknown
      }

      // Execute all scroll steps in a single command for better performance
      if (steps == 1) {
        Process.runSync('xdotool', ['click', buttonNum]);
      } else {
        // Use xdotool's repeat feature which is much faster than looping
        Process.runSync(
            'xdotool', ['click', '--repeat', steps.toString(), buttonNum]);
      }
    } catch (e) {
      print('Linux mouse scroll error: $e');
    }
  }

  String _getButtonNumber(String button) {
    switch (button.toLowerCase()) {
      case 'left':
        return '1';
      case 'middle':
        return '2';
      case 'right':
        return '3';
      default:
        return '1';
    }
  }

  @override
  void handleGesture(String gestureType, {Map<String, dynamic>? data}) {
    if (!_hasXdotool) {
      print('xdotool not available for gesture handling');
      return;
    }

    try {
      switch (gestureType) {
        case 'double_click':
          _performDoubleClick();
          break;
        case 'two_finger_scroll':
          _handleTwoFingerScroll(data);
          break;
        case 'three_finger_swipe':
          _handleThreeFingerSwipe(data);
          break;
        case 'four_finger_swipe':
          _handleFourFingerSwipe(data);
          break;
        case 'pinch_zoom':
          _handlePinchZoom(data);
          break;
        case 'rotate':
          _handleRotate(data);
          break;
        default:
          print('Unsupported gesture: $gestureType');
      }
    } catch (e) {
      print('Linux gesture handling error: $e');
    }
  }

  @override
  void handleKeyboard(String action, {String? text, String? key}) {
    if (!_hasXdotool) {
      print('xdotool not available for keyboard handling');
      return;
    }

    try {
      switch (action) {
        case 'type':
          if (text != null) {
            _typeText(text);
          }
          break;
        case 'key':
          if (key != null) {
            _pressKey(key);
          }
          break;
        case 'backspace':
          _pressKey('BackSpace');
          break;
        case 'enter':
          _pressKey('Return');
          break;
        case 'space':
          _pressKey('space');
          break;
        case 'tab':
          _pressKey('Tab');
          break;
        case 'escape':
          _pressKey('Escape');
          break;
        default:
          print('Unsupported keyboard action: $action');
      }
    } catch (e) {
      print('Linux keyboard handling error: $e');
    }
  }

  void _typeText(String text) {
    try {
      Process.runSync('xdotool', ['type', text]);
    } catch (e) {
      print('Linux text typing error: $e');
    }
  }

  void _pressKey(String key) {
    try {
      Process.runSync('xdotool', ['key', key]);
    } catch (e) {
      print('Linux key press error: $e');
    }
  }

  void _performDoubleClick() {
    // Perform two quick left clicks
    Process.runSync('xdotool', ['click', '--repeat', '2', '1']);
  }

  void _handleTwoFingerScroll(Map<String, dynamic>? data) {
    if (data != null) {
      final direction = data['direction'] as String? ?? 'up';
      final amount = data['amount'] as double? ?? 1.0;
      scroll(direction, amount: amount);
    }
  }

  void _handleThreeFingerSwipe(Map<String, dynamic>? data) {
    if (data != null) {
      final direction = data['direction'] as String? ?? 'left';
      _performLinuxSwipeGesture(direction);
    }
  }

  void _handleFourFingerSwipe(Map<String, dynamic>? data) {
    if (data != null) {
      final direction = data['direction'] as String? ?? 'left';
      _performLinuxFourFingerSwipe(direction);
    }
  }

  void _handlePinchZoom(Map<String, dynamic>? data) {
    if (data != null) {
      final scale = data['scale'] as double? ?? 1.0;
      final isZoomIn = scale > 1.0;

      // Simulate Ctrl + Mouse Wheel for zoom
      if (isZoomIn) {
        Process.runSync('xdotool', ['key', 'ctrl+plus']);
      } else {
        Process.runSync('xdotool', ['key', 'ctrl+minus']);
      }
    }
  }

  void _handleRotate(Map<String, dynamic>? data) {
    // Rotation gestures could be mapped to specific application shortcuts
    print('Rotation gesture received: $data');
  }

  void _performLinuxSwipeGesture(String direction) {
    // Map three-finger swipes to common Linux gestures
    switch (direction) {
      case 'left':
        // Alt + Left (Browser back)
        Process.runSync('xdotool', ['key', 'alt+Left']);
        break;
      case 'right':
        // Alt + Right (Browser forward)
        Process.runSync('xdotool', ['key', 'alt+Right']);
        break;
      case 'up':
        // Super + S (Activities overview in GNOME)
        Process.runSync('xdotool', ['key', 'super+s']);
        break;
      case 'down':
        // Super + D (Show desktop)
        Process.runSync('xdotool', ['key', 'super+d']);
        break;
    }
  }

  void _performLinuxFourFingerSwipe(String direction) {
    // Map four-finger swipes to workspace management gestures
    switch (direction) {
      case 'left':
        // Ctrl + Alt + Left (Previous workspace)
        Process.runSync('xdotool', ['key', 'ctrl+alt+Left']);
        break;
      case 'right':
        // Ctrl + Alt + Right (Next workspace)
        Process.runSync('xdotool', ['key', 'ctrl+alt+Right']);
        break;
      case 'up':
        // Super + A (Show all applications)
        Process.runSync('xdotool', ['key', 'super+a']);
        break;
      case 'down':
        // Super + M (Show notifications)
        Process.runSync('xdotool', ['key', 'super+m']);
        break;
    }
  }

  @override
  void dispose() {
    // Clean up resources if needed
  }
}
