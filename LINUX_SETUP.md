# Remote Mouse - Linux Setup Instructions

## Required Dependencies

### For Ubuntu/Debian:
```bash
sudo apt update
sudo apt install xdotool libayatana-appindicator3-dev
```

### For Arch Linux:
```bash
sudo pacman -S xdotool libayatana-appindicator
```

### For Fedora/CentOS:
```bash
sudo dnf install xdotool libayatana-appindicator3-devel
```

## Installation

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

3. **Run the application**
   ```bash
   # For desktop server
   flutter run -d linux
   
   # Or use the convenience script
   ./run.sh
   ```

## Building for Distribution

```bash
# Build Linux desktop
./build.sh linux

# Build Android APK
./build.sh android

# Build all platforms
./build.sh all
```

## Troubleshooting

### Mouse control not working
- Ensure `xdotool` is installed: `sudo apt install xdotool`
- Check if X11 is running (not Wayland): `echo $XDG_SESSION_TYPE`
- For Wayland, install `ydotool` as alternative

### Network discovery issues
- Ensure both devices are on the same network
- Check firewall settings for port 1978
- Try manual IP connection if auto-discovery fails

### Build issues
- Run `flutter doctor` to check setup
- Update Flutter: `flutter upgrade`
- Clean and rebuild: `flutter clean && flutter pub get`
