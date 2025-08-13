import 'dart:io';

abstract class MouseController {
  void moveMouse(double dx, double dy);
  void click(String button);
  void scroll(String direction, {double amount = 1.0});
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

// Windows implementation using command line tools initially
class WindowsMouseController implements MouseController {
  WindowsMouseController() {
    print('Windows mouse controller initialized');
  }

  @override
  void moveMouse(double dx, double dy) {
    try {
      // For now, use PowerShell to move mouse
      // In production, this would use proper WinAPI calls
      final script = '''
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point(([System.Windows.Forms.Cursor]::Position.X + $dx), ([System.Windows.Forms.Cursor]::Position.Y + $dy))
      ''';

      Process.runSync('powershell', [
        '-Command',
        script
            .replaceAll('\$dx', dx.toString())
            .replaceAll('\$dy', dy.toString())
      ]);
    } catch (e) {
      print('Windows mouse move error: $e');
    }
  }

  @override
  void click(String button) {
    try {
      // Simplified click implementation
      print('Windows click: $button');
      // In production, this would use proper WinAPI SendInput calls
    } catch (e) {
      print('Windows mouse click error: $e');
    }
  }

  @override
  void scroll(String direction, {double amount = 1.0}) {
    try {
      print('Windows scroll: $direction, amount: $amount');
      // In production, this would use proper WinAPI scroll calls
    } catch (e) {
      print('Windows mouse scroll error: $e');
    }
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
      final buttonNum = direction == 'up' ? '4' : '5';
      for (int i = 0; i < amount.round(); i++) {
        Process.runSync('xdotool', ['click', buttonNum]);
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
  void dispose() {
    // Clean up resources if needed
  }
}
