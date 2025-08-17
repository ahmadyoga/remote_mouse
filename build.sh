#!/bin/bash

# Remote Mouse Build Script
# Builds the application for different platforms

echo "🖱️  Remote Mouse Build Script"
echo "============================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Get dependencies and generate code
echo "📦 Installing dependencies..."
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Build function
build_for_platform() {
    local platform=$1
    local output_dir="build_output/$platform"
    
    echo ""
    echo "🔨 Building for $platform..."
    
    mkdir -p "$output_dir"
    
    case $platform in
        "android")
            flutter build apk --release
            if [ $? -eq 0 ]; then
                cp build/app/outputs/flutter-apk/app-release.apk "$output_dir/remote_mouse.apk"
                echo "✅ Android APK: $output_dir/remote_mouse.apk"
            fi
            ;;
        "linux")
            flutter build linux --release
            if [ $? -eq 0 ]; then
                cp -r build/linux/x64/release/bundle/* "$output_dir/"
                echo "✅ Linux build: $output_dir/"
            fi
            ;;
        "windows")
            flutter build windows --release
            if [ $? -eq 0 ]; then
                cp build/windows/x64/runner/Release/* "$output_dir/"
                echo "✅ Windows build: $output_dir/"
            fi
            ;;
        *)
            echo "❌ Unsupported platform: $platform"
            return 1
            ;;
    esac
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: ./build.sh [platform]"
    echo ""
    echo "Available platforms:"
    echo "  android    - Build Android APK"
    echo "  linux      - Build Linux desktop"
    echo "  windows    - Build Windows desktop"
    echo "  all        - Build for all supported platforms"
    echo ""
    echo "Example: ./build.sh android"
    exit 1
fi

if [ "$1" = "all" ]; then
    echo "🌐 Building for all platforms..."
    build_for_platform "android"
    build_for_platform "linux"
    build_for_platform "windows"
else
    build_for_platform "$1"
fi

echo ""
echo "🎉 Build complete!"
echo "📁 Output directory: build_output/"
