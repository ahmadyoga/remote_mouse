@echo off
REM Build test script for Remote Mouse app (Windows version)
REM This script uses the Makefile for testing builds

echo 🚀 Starting Remote Mouse build tests using Makefile...

REM Check if make or nmake is available
where make >nul 2>&1
if not errorlevel 1 (
    echo ✅ GNU Make found, using main Makefile...
    make test-build
    if errorlevel 1 (
        echo ❌ Makefile build failed
        exit /b 1
    )
    goto success
)

where nmake >nul 2>&1
if not errorlevel 1 (
    echo ✅ NMake found, using Windows Makefile...
    nmake -f Makefile.win test-build
    if errorlevel 1 (
        echo ❌ Windows Makefile build failed
        exit /b 1
    )
    goto success
)

REM Fallback to direct Flutter commands
echo ❌ Make/NMake not found, falling back to Flutter commands...

flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is also not installed or not in PATH
    exit /b 1
)

echo 📦 Getting Flutter dependencies...
flutter pub get
if errorlevel 1 (
    echo ❌ Failed to get dependencies
    exit /b 1
)

echo 🔍 Analyzing code...
flutter analyze --fatal-infos
if errorlevel 1 (
    echo ❌ Code analysis failed
    exit /b 1
)

echo 🧪 Running tests...
flutter test
if errorlevel 1 (
    echo ❌ Tests failed
    exit /b 1
)

echo 🤖 Building Android APK (debug)...
flutter build apk --debug
if errorlevel 1 (
    echo ❌ Android build failed
    exit /b 1
)

echo ✅ Fallback build completed successfully!
goto end

:success
echo 🎉 Makefile build test completed successfully!
echo.
echo 📁 Build outputs in: build_output\
echo.
echo 💡 Try other Makefile targets:
if exist Makefile (
    echo   - make help           # Show all available commands
    echo   - make dev            # Full development setup  
    echo   - make build-all      # Build for all platforms
    echo   - make release        # Full release workflow
) else (
    echo   - nmake -f Makefile.win help        # Show available commands
    echo   - nmake -f Makefile.win dev         # Development setup
    echo   - nmake -f Makefile.win build-all   # Build all platforms
    echo   - nmake -f Makefile.win release     # Release workflow
)

:end
