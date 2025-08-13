#!/bin/bash

# Remote Mouse Application Launcher
# This script builds and runs the Remote Mouse application

echo "🖱️  Remote Mouse Application"
echo "=========================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    echo "Please install Flutter first: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check current directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ This script must be run from the project root directory"
    exit 1
fi

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to get dependencies"
    exit 1
fi

# Generate code
echo "🔧 Generating code..."
flutter pub run build_runner build --delete-conflicting-outputs

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate code"
    exit 1
fi

# Detect platform and run appropriate build
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Detected Linux - Building desktop version..."
    
    # Check if xdotool is installed
    if ! command -v xdotool &> /dev/null; then
        echo "⚠️  Warning: xdotool is not installed"
        echo "   Mouse control may not work properly"
        echo "   Install with: sudo apt install xdotool"
        echo ""
    fi
    
    echo "🚀 Starting Linux desktop app..."
    flutter run -d linux --debug
    
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "🪟 Detected Windows - Building desktop version..."
    echo "🚀 Starting Windows desktop app..."
    flutter run -d windows --debug
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detected macOS"
    
    # Check for iOS simulator or run desktop
    if flutter devices | grep -q "iOS Simulator"; then
        echo "📱 iOS Simulator available - Choose target:"
        flutter devices
        echo ""
        echo "Run with: flutter run -d [device-id]"
    else
        echo "🖥️  Running macOS desktop version..."
        flutter run -d macos --debug
    fi
    
else
    echo "❓ Unknown platform: $OSTYPE"
    echo "Available devices:"
    flutter devices
    echo ""
    echo "Choose a device and run: flutter run -d [device-id]"
fi
