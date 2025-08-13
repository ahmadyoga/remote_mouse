# Remote Mouse App – Flutter (Android, Windows, Linux)

A cross-platform **remote mouse control application** using **Flutter** for Android, Windows, and Linux. The mobile app acts as a **full multi-gesture touchpad**, while the desktop app runs as a **background service** and moves the mouse cursor based on received commands.

## Features

### 🎮 Multi-Gesture Touchpad
- **Single-finger move** → Move cursor
- **Single tap** → Left click
- **Double tap** → Double click
- **Long press** → Right click
- **Two-finger scroll** → Scroll up/down
- **Floating buttons** → Quick access to left/right click and scroll

### 🔄 Device Discovery
- **mDNS/Bonjour** for automatic local network device discovery
- **Manual IP entry** as fallback option
- Real-time connection status indicator

### 🖥️ Desktop Server
- Runs in the background on Windows and Linux
- TCP server listening on configurable port (default: 1978)
- Native mouse control using OS APIs
- Simple and clean user interface

### 🔒 Protocol
Simple JSON-based communication:
```json
{"dx": 15, "dy": -3}           // Cursor movement
{"click": "left"}              // Click event
{"scroll": "up"}               // Scroll event
{"gesture": "two_finger_scroll", "dy": -10}  // Multi-finger gestures
```

## Installation & Setup

### Prerequisites
- Flutter SDK (3.3.3 or higher)
- For Linux: `xdotool` package for mouse control
  ```bash
  sudo apt install xdotool  # Ubuntu/Debian
  sudo pacman -S xdotool     # Arch Linux
  ```

### Build Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd remote_mouse
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   flutter pub run build_runner build
   ```

3. **Build for your platform**

   **Android (Mobile):**
   ```bash
   flutter build apk --release
   # Or for development
   flutter run
   ```

   **Linux Desktop:**
   ```bash
   flutter build linux --release
   # Or for development
   flutter run -d linux
   ```

   **Windows Desktop:**
   ```bash
   flutter build windows --release
   # Or for development
   flutter run -d windows
   ```

## Usage

### Setting Up Desktop Server

1. **Run the desktop application** on your Windows or Linux computer
2. **Start the server** by clicking the "Start Server" button
3. **Note the IP address** of your computer (you can find this in your network settings)
4. **Ensure both devices are on the same network**

### Connecting Mobile Device

1. **Open the mobile app** on your Android device
2. **Tap the settings button** (gear icon) in the top-right corner
3. **Choose connection method:**
   - **Automatic:** Wait for devices to appear in the "Discovered Devices" list
   - **Manual:** Enter the desktop computer's IP address and port (default: 1978)
4. **Tap to connect** to your desktop

### Using the Touchpad

Once connected, you can use the mobile device as a touchpad:

- **Move finger** on the black area to move the mouse cursor
- **Single tap** for left click
- **Long press** for right click
- **Two-finger scroll** for scrolling
- **Use floating buttons** for quick access to clicks and scroll

## Project Structure

```
remote_mouse/
├── lib/
│   ├── main.dart                    # Main entry point
│   ├── models/                      # Data models
│   │   ├── app_state.dart          # App states and constants
│   │   ├── device_info.dart        # Device information model
│   │   └── mouse_event.dart        # Mouse event model
│   ├── services/                    # Core services
│   │   ├── discovery_service.dart   # mDNS device discovery
│   │   ├── network_service.dart     # TCP networking
│   │   ├── mouse_control_service.dart # Native mouse control
│   │   └── gesture_service.dart     # Gesture recognition
│   ├── providers/                   # State management
│   │   └── remote_mouse_provider.dart
│   └── screens/                     # UI screens
│       ├── touchpad_screen.dart     # Mobile touchpad interface
│       └── desktop_screen.dart      # Desktop server interface
├── android/                         # Android platform files
├── linux/                          # Linux platform files
├── windows/                         # Windows platform files
└── pubspec.yaml                     # Dependencies
```

## Technical Details

### Networking
- **TCP server** on desktop using `dart:io`
- **TCP client** on mobile using `dart:io`
- **mDNS discovery** using `multicast_dns` package
- **JSON protocol** for message serialization

### Mouse Control
- **Linux:** Uses `xdotool` command-line tool for mouse control
- **Windows:** Uses PowerShell commands (can be extended with WinAPI)
- **Cross-platform:** Abstracted through `MouseController` interface

### Dependencies
- `provider` - State management
- `multicast_dns` - Device discovery
- `network_info_plus` - Network information
- `json_annotation` - JSON serialization
- `crypto` - Security utilities
- `shared_preferences` - Settings storage

## Configuration

### Default Settings
- **Port:** 1978
- **Mouse sensitivity:** 2.0x
- **Scroll sensitivity:** 1.5x
- **Double-click threshold:** 300ms
- **Discovery timeout:** 5 seconds

### Customization
You can modify these settings in `lib/models/app_state.dart`:

```dart
class AppConstants {
  static const int defaultPort = 1978;
  static const double mouseSensitivity = 2.0;
  static const double scrollSensitivity = 1.5;
  // ... more settings
}
```

## Troubleshooting

### Connection Issues
1. **Ensure both devices are on the same network**
2. **Check firewall settings** - make sure the port (1978) is not blocked
3. **Try manual IP connection** if automatic discovery fails
4. **Restart the server** if connection drops

### Linux Mouse Control Issues
1. **Install xdotool:** `sudo apt install xdotool`
2. **Check permissions** - some systems may require additional setup
3. **For Wayland users:** X11 tools may not work, consider using alternative tools

### Performance Issues
1. **Reduce mouse sensitivity** in the constants
2. **Ensure good network connection** between devices
3. **Close unnecessary applications** on both devices

## Development

### Adding New Gestures
1. Modify `GestureService` to recognize new gestures
2. Add corresponding mouse actions in `MouseController`
3. Update the protocol in `MouseEvent` model

### Platform Support
The app automatically detects the platform and shows the appropriate interface:
- **Mobile platforms** (Android/iOS) → Touchpad interface
- **Desktop platforms** (Windows/Linux/macOS) → Server interface
- **Web/Unknown** → Manual mode selection

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both mobile and desktop
5. Submit a pull request

## License

This project is open source. See the LICENSE file for details.

## Future Enhancements

- [ ] System tray integration for desktop
- [ ] Auto-start on system boot
- [ ] Security with pairing codes
- [ ] Keyboard input support
- [ ] Multiple device connections
- [ ] Gesture customization
- [ ] macOS support
- [ ] iOS support
