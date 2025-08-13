import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_state.dart';
import '../models/device_info.dart';
import '../models/mouse_event.dart';
import '../services/discovery_service.dart';
import '../services/network_service.dart';
import '../services/mouse_control_service.dart';
import '../services/gesture_service.dart';

class RemoteMouseProvider with ChangeNotifier {
  static final RemoteMouseProvider _instance = RemoteMouseProvider._internal();
  factory RemoteMouseProvider() => _instance;
  RemoteMouseProvider._internal();

  // App State
  AppMode _appMode = AppMode.mobile;
  ConnectionState _connectionState = ConnectionState.disconnected;
  final List<DeviceInfo> _discoveredDevices = [];
  DeviceInfo? _connectedDevice;
  String? _errorMessage;
  int _serverPort = AppConstants.defaultPort;
  bool _isServerRunning = false;

  // Settings
  AppSettings _appSettings = AppSettings();
  AppSettings get appSettings => _appSettings;

  // Services
  final DeviceDiscoveryService _discoveryService = DeviceDiscoveryService();
  final NetworkService _networkService = NetworkService();
  final GestureService _gestureService = GestureService();
  MouseController? _mouseController;

  // Getters
  AppMode get appMode => _appMode;
  ConnectionState get connectionState => _connectionState;
  List<DeviceInfo> get discoveredDevices => _discoveredDevices;
  DeviceInfo? get connectedDevice => _connectedDevice;
  String? get errorMessage => _errorMessage;
  int get serverPort => _serverPort;
  bool get isServerRunning => _isServerRunning;

  // Initialize the provider
  Future<void> initialize({required AppMode mode}) async {
    _appMode = mode;

    // Load saved settings
    await _loadSettings();

    if (_appMode == AppMode.desktop) {
      _initializeDesktop();
    } else {
      _initializeMobile();
    }

    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final mouseSensitivity =
          prefs.getDouble('mouse_sensitivity') ?? AppConstants.mouseSensitivity;
      final scrollSensitivity = prefs.getDouble('scroll_sensitivity') ??
          AppConstants.scrollSensitivity;
      final doubleClickThreshold = prefs.getDouble('double_click_threshold') ??
          AppConstants.doubleClickThreshold;

      _appSettings = AppSettings(
        mouseSensitivity: mouseSensitivity,
        scrollSensitivity: scrollSensitivity,
        doubleClickThreshold: doubleClickThreshold,
      );
    } catch (e) {
      print('Failed to load settings: $e');
      _appSettings = AppSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setDouble('mouse_sensitivity', _appSettings.mouseSensitivity);
      await prefs.setDouble(
          'scroll_sensitivity', _appSettings.scrollSensitivity);
      await prefs.setDouble(
          'double_click_threshold', _appSettings.doubleClickThreshold);
    } catch (e) {
      print('Failed to save settings: $e');
    }
  }

  void _initializeDesktop() {
    // Initialize mouse controller for desktop
    try {
      _mouseController = MouseControllerFactory.create();
      print('Mouse controller initialized: ${_mouseController.runtimeType}');

      // Listen to network events for mouse control
      _networkService.eventStream.listen((MouseEvent event) {
        print('Received mouse event: $event');
        _handleMouseEvent(event);
      });

      // Listen to connection state changes
      _networkService.connectionStream.listen((ConnectionState state) {
        print('Connection state changed: $state');
        _connectionState = state;
        notifyListeners();
      });

      // Start the TCP server
      _startDesktopServer();

      print('Desktop initialization completed');
    } catch (e) {
      print('Failed to initialize desktop mode: $e');
      _errorMessage = 'Failed to initialize desktop mode: $e';
      notifyListeners();
    }
  }

  Future<void> _startDesktopServer() async {
    try {
      await _networkService.startServer(port: _serverPort);
      _isServerRunning = true;
      print('Desktop TCP server started on port $_serverPort');
      notifyListeners();
    } catch (e) {
      print('Failed to start desktop server: $e');
      _errorMessage = 'Failed to start server: $e';
      _isServerRunning = false;
      notifyListeners();
    }
  }

  void _initializeMobile() {
    // Initialize gesture service for mobile
    _gestureService.initialize();
    _gestureService.updateSettings(_appSettings);

    // Listen to gesture events and send them over network
    _gestureService.gestureStream.listen((MouseEvent event) {
      _networkService.sendMouseEvent(event);
    });

    // Listen to connection state changes
    _networkService.connectionStream.listen((ConnectionState state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  void _handleMouseEvent(MouseEvent event) {
    print('Handling mouse event: $event');

    if (_mouseController == null) {
      print('Mouse controller is null!');
      return;
    }

    try {
      if (event.dx != null && event.dy != null) {
        // Mouse movement
        print('Moving mouse: dx=${event.dx}, dy=${event.dy}');
        _mouseController!.moveMouse(event.dx!, event.dy!);
      } else if (event.click != null) {
        // Mouse click
        print('Clicking mouse: ${event.click}');
        _mouseController!.click(event.click!);
      } else if (event.scroll != null) {
        // Scroll
        print('Scrolling: ${event.scroll}');
        _mouseController!.scroll(event.scroll!);
      } else if (event.gesture != null) {
        // Handle gestures
        print('Handling gesture: ${event.gesture}');
        _handleGestureEvent(event);
      }
    } catch (e) {
      print('Mouse event handling error: $e');
    }
  }

  void _handleGestureEvent(MouseEvent event) {
    switch (event.gesture) {
      case 'double_click':
        _mouseController!.click('left');
        _mouseController!.click('left');
        break;
      case 'two_finger_scroll':
        final data = event.data;
        if (data != null) {
          final direction = data['direction'] as String? ?? 'up';
          final amount = data['amount'] as double? ?? 1.0;
          _mouseController!.scroll(direction, amount: amount);
        }
        break;
    }
  }

  // Device Discovery
  Future<void> startDiscovery() async {
    if (_appMode != AppMode.mobile) return;

    try {
      _discoveredDevices.clear();
      notifyListeners();

      await _discoveryService.startDiscovery();

      _discoveryService.deviceStream.listen((DeviceInfo device) {
        if (!_discoveredDevices
            .any((d) => d.ip == device.ip && d.port == device.port)) {
          _discoveredDevices.add(device);
          notifyListeners();
        }
      });
    } catch (e) {
      _errorMessage = 'Discovery failed: $e';
      print(_errorMessage);
      notifyListeners();
    }
  }

  Future<void> stopDiscovery() async {
    await _discoveryService.stopDiscovery();
  }

  // Connection Management
  Future<void> connectToDevice(DeviceInfo device) async {
    if (_appMode != AppMode.mobile) return;

    try {
      _errorMessage = null;
      await _networkService.connectToServer(device);
      _connectedDevice = device;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _networkService.disconnect();
      _connectedDevice = null;
      _connectionState = ConnectionState.disconnected;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Disconnect failed: $e';
      notifyListeners();
    }
  }

  // Server Management (Desktop)
  Future<void> startServer() async {
    if (_appMode != AppMode.mobile) {
      try {
        await _networkService.startServer(port: _serverPort);
        _isServerRunning = true;

        // Announce service for discovery
        await _discoveryService.announceService(
            port: _serverPort, deviceName: 'Desktop Remote Mouse');

        notifyListeners();
      } catch (e) {
        _errorMessage = 'Server start failed: $e';
        notifyListeners();
      }
    }
  }

  Future<void> stopServer() async {
    try {
      await _networkService.stopServer();
      await _discoveryService.stopDiscovery();
      _isServerRunning = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Server stop failed: $e';
      notifyListeners();
    }
  }

  void setServerPort(int port) {
    _serverPort = port;
    notifyListeners();
  }

  // Manual connection
  Future<void> connectToIP(String ip, int port) async {
    final device = DeviceInfo(
      name: 'Manual Connection',
      ip: ip,
      port: port,
    );
    await connectToDevice(device);
  }

  // Gesture forwarding
  void onPanStart(DragStartDetails details) {
    if (_appMode == AppMode.mobile) {
      _gestureService.onPanStart(details);
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (_appMode == AppMode.mobile) {
      _gestureService.onPanUpdate(details);
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (_appMode == AppMode.mobile) {
      _gestureService.onPanEnd(details);
    }
  }

  void onTap() {
    if (_appMode == AppMode.mobile) {
      _gestureService.onTap();
    }
  }

  void onScaleStart(ScaleStartDetails details) {
    if (_appMode == AppMode.mobile) {
      _gestureService.onScaleStart(details);
    }
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    if (_appMode == AppMode.mobile) {
      _gestureService.onScaleUpdate(details);
    }
  }

  void onScaleEnd(ScaleEndDetails details) {
    if (_appMode == AppMode.mobile) {
      _gestureService.onScaleEnd(details);
    }
  }

  void onLongPress() {
    if (_appMode == AppMode.mobile) {
      _gestureService.onLongPress();
    }
  }

  void simulateClick(String button) {
    if (_appMode == AppMode.mobile) {
      _gestureService.simulateClick(button);
    }
  }

  void simulateScroll(String direction) {
    if (_appMode == AppMode.mobile) {
      _gestureService.simulateScroll(direction);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Settings management
  void updateSettings(AppSettings settings) {
    _appSettings = settings;
    _gestureService.updateSettings(settings);
    _saveSettings();
    notifyListeners();
  }

  void updateMouseSensitivity(double sensitivity) {
    _appSettings = _appSettings.copyWith(mouseSensitivity: sensitivity);
    _gestureService.updateSettings(_appSettings);
    _saveSettings();
    notifyListeners();
  }

  void updateScrollSensitivity(double sensitivity) {
    _appSettings = _appSettings.copyWith(scrollSensitivity: sensitivity);
    _gestureService.updateSettings(_appSettings);
    _saveSettings();
    notifyListeners();
  }

  void updateDoubleClickThreshold(double threshold) {
    _appSettings = _appSettings.copyWith(doubleClickThreshold: threshold);
    _gestureService.updateSettings(_appSettings);
    _saveSettings();
    notifyListeners();
  }

  @override
  void dispose() {
    _discoveryService.dispose();
    _networkService.dispose();
    _gestureService.dispose();
    _mouseController?.dispose();
    super.dispose();
  }
}
