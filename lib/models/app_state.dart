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

class AppSettings {
  double mouseSensitivity;
  double scrollSensitivity;
  int tapTimeout;
  double tapThreshold;
  double doubleClickThreshold;
  bool reverseScroll;

  AppSettings({
    this.mouseSensitivity = 2.0,
    this.scrollSensitivity = 1.5,
    this.tapTimeout = 200,
    this.tapThreshold = 10.0,
    this.doubleClickThreshold = 300,
    this.reverseScroll = false,
  });

  AppSettings copyWith({
    double? mouseSensitivity,
    double? scrollSensitivity,
    int? tapTimeout,
    double? tapThreshold,
    double? doubleClickThreshold,
    bool? reverseScroll,
  }) {
    return AppSettings(
      mouseSensitivity: mouseSensitivity ?? this.mouseSensitivity,
      scrollSensitivity: scrollSensitivity ?? this.scrollSensitivity,
      tapTimeout: tapTimeout ?? this.tapTimeout,
      tapThreshold: tapThreshold ?? this.tapThreshold,
      doubleClickThreshold: doubleClickThreshold ?? this.doubleClickThreshold,
      reverseScroll: reverseScroll ?? this.reverseScroll,
    );
  }
}

class AppConstants {
  static const int defaultPort = 1978;
  static const String serviceName = '_remotemouse._tcp';
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration discoveryTimeout = Duration(seconds: 5);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  // Default gesture sensitivity settings (can be overridden by AppSettings)
  static const double mouseSensitivity = 2.0;
  static const double scrollSensitivity = 1.5;
  static const int tapTimeout = 200; // milliseconds
  static const double tapThreshold = 10.0; // pixels
  static const double doubleClickThreshold = 300; // milliseconds

  // Security
  static const int pairingCodeLength = 6;
  static const Duration pairingTimeout = Duration(minutes: 2);
}
