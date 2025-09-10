#!/bin/bash

# Build test script for Remote Mouse app
# This script uses the Makefile for testing builds

set -e  # Exit on any error

echo "🚀 Starting Remote Mouse build tests using Makefile..."

# Check if make is available
if ! command -v make &> /dev/null; then
    echo "❌ Make is not installed or not in PATH"
    echo "ℹ️  Falling back to direct Flutter commands..."
    
    # Fallback to direct Flutter commands
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter is also not installed or not in PATH"
        exit 1
    fi
    
    echo "📦 Getting Flutter dependencies..."
    flutter pub get
    
    echo "🔍 Analyzing code..."
    flutter analyze --fatal-infos
    
    echo "🧪 Running tests..."
    flutter test
    
    echo "🤖 Building Android APK (debug)..."
    flutter build apk --debug
    
    echo "✅ Fallback build completed successfully!"
    exit 0
fi

echo "✅ Make found, using Makefile..."

# Use Makefile for build testing
echo "🧪 Running test build workflow..."
make test-build

echo ""
echo "🎉 Makefile build test completed successfully!"
echo ""
echo "📁 Build outputs:"
echo "  - Android APK: build_output/android-debug/"
echo ""
echo "💡 Try other Makefile targets:"
echo "  - make help      # Show all available commands"
echo "  - make dev       # Full development setup"
echo "  - make build-all # Build for all platforms"
echo "  - make release   # Full release workflow"
