# Remote Mouse Application Makefile
# Cross-platform build system for Flutter Remote Mouse app

# Variables
FLUTTER := flutter
PLATFORM := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m)
BUILD_DIR := build_output
APP_NAME := remote_mouse
VERSION := 1.0.0
FLUTTER_VERSION := $(shell grep -o '"flutter": "[^"]*"' .fvmrc 2>/dev/null | cut -d'"' -f4 || echo "unknown")

# Helper function to use FVM if available, otherwise use system Flutter
define flutter_cmd
	$(if $(shell command -v fvm 2>/dev/null && test -f .fvmrc && echo "1"),fvm flutter,$(FLUTTER))
endef

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
WHITE := \033[0;37m
NC := \033[0m # No Color

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "$(CYAN)🖱️  Remote Mouse Application Makefile$(NC)"
	@echo "$(CYAN)=====================================$(NC)"
	@echo ""
	@echo "$(WHITE)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Check if Flutter is installed
.PHONY: check-flutter
check-flutter:
	@which $(FLUTTER) > /dev/null || (echo "$(RED)❌ Flutter is not installed or not in PATH$(NC)" && exit 1)
	@echo "$(GREEN)✅ Flutter found: $(shell $(FLUTTER) --version | head -n1)$(NC)"
	@if [ "$(FLUTTER_VERSION)" != "unknown" ]; then \
		echo "$(CYAN)📋 FVM configured version: $(FLUTTER_VERSION)$(NC)"; \
	fi

# Check if we're in the right directory
.PHONY: check-project
check-project:
	@test -f pubspec.yaml || (echo "$(RED)❌ This must be run from the project root directory$(NC)" && exit 1)
	@echo "$(GREEN)✅ Project root confirmed$(NC)"

# Install dependencies
.PHONY: deps
deps: check-flutter check-project ## Install Flutter dependencies
	@echo "$(BLUE)📦 Getting Flutter dependencies...$(NC)"
	@if command -v fvm >/dev/null 2>&1 && [ -f .fvmrc ]; then \
		echo "$(CYAN)🔧 Using FVM with Flutter $(FLUTTER_VERSION)$(NC)"; \
	fi
	@$(call flutter_cmd) pub get

# Generate code
.PHONY: generate
generate: deps ## Generate code using build_runner
	@echo "$(BLUE)🔧 Generating code...$(NC)"
	@if grep -q "build_runner" pubspec.yaml; then \
		$(call flutter_cmd) pub run build_runner build --delete-conflicting-outputs; \
	else \
		echo "$(YELLOW)ℹ️  No build_runner found, skipping code generation$(NC)"; \
	fi

# Clean build artifacts
.PHONY: clean
clean: ## Clean build artifacts
	@echo "$(BLUE)🧹 Cleaning build artifacts...$(NC)"
	@$(FLUTTER) clean
	@rm -rf $(BUILD_DIR)
	@echo "$(GREEN)✅ Clean complete$(NC)"

# Analyze code
.PHONY: analyze
analyze: deps ## Run Flutter analyze
	@echo "$(BLUE)🔍 Analyzing code...$(NC)"
	@$(call flutter_cmd) analyze --fatal-infos

# Run tests
.PHONY: test
test: deps ## Run Flutter tests
	@echo "$(BLUE)🧪 Running tests...$(NC)"
	@$(call flutter_cmd) test

# Format code
.PHONY: format
format: ## Format Dart code
	@echo "$(BLUE)✨ Formatting code...$(NC)"
	@$(call flutter_cmd) format .

# Check everything (analyze + test)
.PHONY: check
check: analyze test ## Run both analyze and test
	@echo "$(GREEN)✅ All checks passed$(NC)"

# Development run targets
.PHONY: run
run: generate ## Run the app (auto-detect platform)
	@echo "$(BLUE)🚀 Starting application...$(NC)"
ifeq ($(PLATFORM),linux)
	@echo "$(BLUE)🐧 Detected Linux - Running desktop version...$(NC)"
	@which xdotool > /dev/null || echo "$(YELLOW)⚠️  Warning: xdotool not installed. Run: sudo apt install xdotool$(NC)"
	@$(call flutter_cmd) run -d linux --debug
else ifeq ($(PLATFORM),darwin)
	@echo "$(BLUE)🍎 Detected macOS - Running desktop version...$(NC)"
	@$(call flutter_cmd) run -d macos --debug
else
	@echo "$(BLUE)🪟 Assuming Windows - Running desktop version...$(NC)"
	@$(call flutter_cmd) run -d windows --debug
endif

.PHONY: run-android
run-android: generate ## Run on Android device/emulator
	@echo "$(BLUE)🤖 Running Android version...$(NC)"
	@$(FLUTTER) run -d android --debug

.PHONY: run-web
run-web: generate ## Run web version
	@echo "$(BLUE)🌐 Running web version...$(NC)"
	@$(FLUTTER) run -d web-server --debug

# Build targets
.PHONY: build-android
build-android: generate ## Build Android APK
	@echo "$(BLUE)🤖 Building Android APK...$(NC)"
	@mkdir -p $(BUILD_DIR)/android
	@$(call flutter_cmd) build apk --release --split-per-abi
	@cp build/app/outputs/flutter-apk/*.apk $(BUILD_DIR)/android/
	@echo "$(GREEN)✅ Android APK built: $(BUILD_DIR)/android/$(NC)"

.PHONY: build-android-bundle
build-android-bundle: generate ## Build Android App Bundle (AAB)
	@echo "$(BLUE)🤖 Building Android App Bundle...$(NC)"
	@mkdir -p $(BUILD_DIR)/android
	@$(FLUTTER) build appbundle --release
	@cp build/app/outputs/bundle/release/*.aab $(BUILD_DIR)/android/
	@echo "$(GREEN)✅ Android AAB built: $(BUILD_DIR)/android/$(NC)"

.PHONY: build-linux
build-linux: generate ## Build Linux desktop app
	@echo "$(BLUE)🐧 Building Linux desktop app...$(NC)"
	@mkdir -p $(BUILD_DIR)/linux
	@$(FLUTTER) build linux --release
	@cp -r build/linux/x64/release/bundle/* $(BUILD_DIR)/linux/
	@echo "$(GREEN)✅ Linux build: $(BUILD_DIR)/linux/$(NC)"

.PHONY: build-windows
build-windows: generate ## Build Windows desktop app
	@echo "$(BLUE)🪟 Building Windows desktop app...$(NC)"
	@mkdir -p $(BUILD_DIR)/windows
	@$(FLUTTER) build windows --release
	@cp -r build/windows/x64/runner/Release/* $(BUILD_DIR)/windows/
	@echo "$(GREEN)✅ Windows build: $(BUILD_DIR)/windows/$(NC)"

.PHONY: build-web
build-web: generate ## Build web app
	@echo "$(BLUE)🌐 Building web app...$(NC)"
	@mkdir -p $(BUILD_DIR)/web
	@$(FLUTTER) build web --release
	@cp -r build/web/* $(BUILD_DIR)/web/
	@echo "$(GREEN)✅ Web build: $(BUILD_DIR)/web/$(NC)"

.PHONY: build-macos
build-macos: generate ## Build macOS desktop app
	@echo "$(BLUE)🍎 Building macOS desktop app...$(NC)"
	@mkdir -p $(BUILD_DIR)/macos
	@$(FLUTTER) build macos --release
	@cp -r build/macos/Build/Products/Release/*.app $(BUILD_DIR)/macos/
	@echo "$(GREEN)✅ macOS build: $(BUILD_DIR)/macos/$(NC)"

# Build all platforms
.PHONY: build-all
build-all: build-android build-linux build-windows build-web ## Build for all platforms
	@echo "$(GREEN)🌐 All platform builds complete!$(NC)"

# Debug builds (faster for testing)
.PHONY: build-android-debug
build-android-debug: generate ## Build Android APK (debug)
	@echo "$(BLUE)🤖 Building Android APK (debug)...$(NC)"
	@mkdir -p $(BUILD_DIR)/android-debug
	@$(FLUTTER) build apk --debug
	@cp build/app/outputs/flutter-apk/*.apk $(BUILD_DIR)/android-debug/
	@echo "$(GREEN)✅ Android debug APK: $(BUILD_DIR)/android-debug/$(NC)"

.PHONY: build-linux-debug
build-linux-debug: generate ## Build Linux app (debug)
	@echo "$(BLUE)🐧 Building Linux app (debug)...$(NC)"
	@mkdir -p $(BUILD_DIR)/linux-debug
	@$(FLUTTER) build linux --debug
	@cp -r build/linux/x64/debug/bundle/* $(BUILD_DIR)/linux-debug/
	@echo "$(GREEN)✅ Linux debug build: $(BUILD_DIR)/linux-debug/$(NC)"

.PHONY: build-windows-debug
build-windows-debug: generate ## Build Windows app (debug)
	@echo "$(BLUE)🪟 Building Windows app (debug)...$(NC)"
	@mkdir -p $(BUILD_DIR)/windows-debug
	@$(FLUTTER) build windows --debug
	@cp -r build/windows/x64/runner/Debug/* $(BUILD_DIR)/windows-debug/
	@echo "$(GREEN)✅ Windows debug build: $(BUILD_DIR)/windows-debug/$(NC)"

# Package builds
.PHONY: package-linux
package-linux: build-linux ## Package Linux build as tar.gz
	@echo "$(BLUE)📦 Packaging Linux build...$(NC)"
	@cd $(BUILD_DIR) && tar -czf $(APP_NAME)-linux-$(VERSION).tar.gz linux/
	@echo "$(GREEN)✅ Linux package: $(BUILD_DIR)/$(APP_NAME)-linux-$(VERSION).tar.gz$(NC)"

.PHONY: package-windows
package-windows: build-windows ## Package Windows build as zip
	@echo "$(BLUE)📦 Packaging Windows build...$(NC)"
	@cd $(BUILD_DIR) && zip -r $(APP_NAME)-windows-$(VERSION).zip windows/
	@echo "$(GREEN)✅ Windows package: $(BUILD_DIR)/$(APP_NAME)-windows-$(VERSION).zip$(NC)"

# Install system dependencies
.PHONY: install-deps-linux
install-deps-linux: ## Install Linux system dependencies
	@echo "$(BLUE)📦 Installing Linux system dependencies...$(NC)"
	@sudo apt update
	@sudo apt install -y xdotool cmake ninja-build libgtk-3-dev
	@echo "$(GREEN)✅ Linux dependencies installed$(NC)"

.PHONY: install-fvm
install-fvm: ## Install Flutter Version Management (FVM)
	@echo "$(BLUE)📦 Installing FVM...$(NC)"
	@if command -v dart >/dev/null 2>&1; then \
		dart pub global activate fvm; \
		echo "$(GREEN)✅ FVM installed via Dart pub$(NC)"; \
	elif command -v npm >/dev/null 2>&1; then \
		npm install -g @leoafarias/fvm; \
		echo "$(GREEN)✅ FVM installed via npm$(NC)"; \
	else \
		echo "$(RED)❌ Neither Dart nor npm found. Please install Flutter or Node.js first$(NC)"; \
		exit 1; \
	fi

.PHONY: setup-fvm
setup-fvm: install-fvm ## Setup FVM and install configured Flutter version
	@if [ -f .fvmrc ]; then \
		echo "$(BLUE)🔧 Setting up FVM with Flutter $(FLUTTER_VERSION)...$(NC)"; \
		fvm install $(FLUTTER_VERSION); \
		fvm use $(FLUTTER_VERSION); \
		echo "$(GREEN)✅ FVM configured with Flutter $(FLUTTER_VERSION)$(NC)"; \
	else \
		echo "$(RED)❌ .fvmrc file not found$(NC)"; \
		exit 1; \
	fi

# App renaming (for boilerplate setup)
.PHONY: change-app-name
change-app-name: ## Change app name and package ID (requires APP_NAME and PACKAGE_NAME env vars)
	@if [ -z "$(APP_NAME)" ] || [ -z "$(PACKAGE_NAME)" ]; then \
		echo "$(RED)❌ APP_NAME and PACKAGE_NAME environment variables are required$(NC)"; \
		echo "$(YELLOW)Usage: APP_NAME='My App' PACKAGE_NAME='com.example.myapp' make change-app-name$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔧 Renaming app to '$(APP_NAME)' with package '$(PACKAGE_NAME)'...$(NC)"
	@$(call flutter_cmd) pub global activate rename
	@$(call flutter_cmd) pub global run rename setAppName --targets ios,android --value "$(APP_NAME)"
	@$(call flutter_cmd) pub global run rename setBundleId --targets ios,android --value "$(PACKAGE_NAME)"
	@echo "$(GREEN)✅ App renamed successfully$(NC)"

.PHONY: install-deps-arch
install-deps-arch: ## Install Arch Linux system dependencies
	@echo "$(BLUE)📦 Installing Arch Linux system dependencies...$(NC)"
	@sudo pacman -Syu xdotool cmake ninja gtk3
	@echo "$(GREEN)✅ Arch Linux dependencies installed$(NC)"

# Development helpers
.PHONY: devices
devices: ## List available Flutter devices
	@$(FLUTTER) devices

.PHONY: doctor
doctor: ## Run Flutter doctor
	@$(FLUTTER) doctor

.PHONY: version
version: ## Show Flutter and project version
	@echo "$(CYAN)Flutter Version:$(NC)"
	@$(FLUTTER) --version
	@echo ""
	@echo "$(CYAN)Project Version:$(NC) $(VERSION)"

# Quick development workflow
.PHONY: dev
dev: clean deps generate check ## Full development setup (clean, deps, generate, check)
	@echo "$(GREEN)🎉 Development environment ready!$(NC)"

# Quick test build
.PHONY: test-build
test-build: generate analyze test build-android-debug ## Quick test build (Android debug)
	@echo "$(GREEN)🎉 Test build complete!$(NC)"

# Release workflow
.PHONY: release
release: clean generate check build-all package-linux package-windows ## Full release build
	@echo "$(GREEN)🎉 Release builds complete!$(NC)"
	@echo "$(CYAN)📁 Build artifacts in: $(BUILD_DIR)/$(NC)"

# Show build info
.PHONY: info
info: ## Show build information
	@echo "$(CYAN)🖱️  Remote Mouse Build Info$(NC)"
	@echo "$(CYAN)===========================$(NC)"
	@echo "$(WHITE)Platform:$(NC) $(PLATFORM)"
	@echo "$(WHITE)Architecture:$(NC) $(ARCH)"
	@echo "$(WHITE)Build Directory:$(NC) $(BUILD_DIR)"
	@echo "$(WHITE)App Name:$(NC) $(APP_NAME)"
	@echo "$(WHITE)Version:$(NC) $(VERSION)"
	@echo "$(WHITE)FVM Flutter Version:$(NC) $(FLUTTER_VERSION)"
	@echo ""
	@$(MAKE) --version | head -n1
	@echo ""
