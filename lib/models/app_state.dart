enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

enum AppMode {
  mobile,
  desktop,
}

class AppConstants {
  static const int defaultPort = 1978;
  static const String serviceName = '_remotemouse._tcp';
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration discoveryTimeout = Duration(seconds: 5);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  // Gesture sensitivity settings
  static const double mouseSensitivity = 2.0;
  static const double scrollSensitivity = 1.5;
  static const int tapTimeout = 200; // milliseconds
  static const double tapThreshold = 10.0; // pixels
  static const double doubleClickThreshold = 300; // milliseconds

  // Security
  static const int pairingCodeLength = 6;
  static const Duration pairingTimeout = Duration(minutes: 2);
}
