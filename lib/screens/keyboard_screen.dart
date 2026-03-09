import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart' as app_state;
import '../theme/app_theme.dart';

class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});

  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends State<KeyboardScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
    final currentText = _textController.text;

    if (currentText.length > _lastText.length) {
      final addedText = currentText.substring(_lastText.length);
      provider.typeText(addedText);
    } else if (currentText.length < _lastText.length) {
      final removedCount = _lastText.length - currentText.length;
      for (int i = 0; i < removedCount; i++) {
        provider.pressBackspace();
      }
    }
    _lastText = currentText;
  }

  void _handleSpecialKey(String key) {
    final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
    switch (key) {
      case 'enter':
        provider.pressEnter();
        break;
      case 'space':
        provider.pressSpace();
        _textController.text += ' ';
        break;
      case 'backspace':
        provider.pressBackspace();
        if (_textController.text.isNotEmpty) {
          _textController.text = _textController.text
              .substring(0, _textController.text.length - 1);
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        }
        break;
      case 'tab':
        provider.pressTab();
        break;
      case 'escape':
        provider.pressEscape();
        break;
      default:
        provider.pressKey(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Keyboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // ── Connection status banner ──
              _ConnectionBanner(state: provider.connectionState, provider: provider),

              // ── Text input area ──
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: glassDecoration(opacity: 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              color: AppColors.primary.withValues(alpha: 0.6),
                              size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Type here to send text to desktop',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            filled: false,
                            hintText: 'Start typing...',
                            hintStyle: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 18,
                            ),
                          ),
                          enabled: provider.connectionState ==
                              app_state.ConnectionState.connected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Special keys ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Special Keys',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // First row
                    Row(
                      children: [
                        _SpecialKey(label: 'Tab', keyName: 'tab', onTap: _handleSpecialKey),
                        const SizedBox(width: 8),
                        _SpecialKey(label: 'Space', keyName: 'space', onTap: _handleSpecialKey),
                        const SizedBox(width: 8),
                        _SpecialKey(label: 'Enter', keyName: 'enter', onTap: _handleSpecialKey, accent: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row
                    Row(
                      children: [
                        _SpecialKey(label: '⌫', keyName: 'backspace', onTap: _handleSpecialKey),
                        const SizedBox(width: 8),
                        _SpecialKey(label: 'Esc', keyName: 'escape', onTap: _handleSpecialKey),
                        const SizedBox(width: 8),
                        _SpecialKey(
                          label: 'Clear',
                          keyName: 'clear',
                          onTap: (_) {
                            _textController.clear();
                            _lastText = '';
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Arrow keys
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ArrowKey(label: '↑', keyName: 'up', onTap: _handleSpecialKey),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ArrowKey(label: '←', keyName: 'left', onTap: _handleSpecialKey),
                        const SizedBox(width: 6),
                        _ArrowKey(label: '↓', keyName: 'down', onTap: _handleSpecialKey),
                        const SizedBox(width: 6),
                        _ArrowKey(label: '→', keyName: 'right', onTap: _handleSpecialKey),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Warning when disconnected ──
              if (provider.connectionState !=
                  app_state.ConnectionState.connected)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.connecting.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.connecting.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.connecting.withValues(alpha: 0.8),
                          size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Connect to a desktop device to use the keyboard',
                          style: TextStyle(
                            color: AppColors.connecting,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Connection Banner ──

class _ConnectionBanner extends StatelessWidget {
  final app_state.ConnectionState state;
  final RemoteMouseProvider provider;

  const _ConnectionBanner({required this.state, required this.provider});

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.25))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          if (provider.connectedDevice != null) ...[
            const Spacer(),
            Text(
              '${provider.connectedDevice!.ip}:${provider.connectedDevice!.port}',
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _color {
    switch (state) {
      case app_state.ConnectionState.connected:
        return AppColors.connected;
      case app_state.ConnectionState.connecting:
      case app_state.ConnectionState.reconnecting:
        return AppColors.connecting;
      case app_state.ConnectionState.error:
        return AppColors.error;
      case app_state.ConnectionState.disconnected:
        return AppColors.disconnected;
    }
  }

  String get _text {
    switch (state) {
      case app_state.ConnectionState.connected:
        return 'Connected — Keyboard Active';
      case app_state.ConnectionState.connecting:
        return 'Connecting...';
      case app_state.ConnectionState.reconnecting:
        return 'Reconnecting...';
      case app_state.ConnectionState.error:
        return 'Connection Error';
      case app_state.ConnectionState.disconnected:
        return 'Not Connected';
    }
  }
}

// ── Special Key Button ──

class _SpecialKey extends StatelessWidget {
  final String label;
  final String keyName;
  final void Function(String) onTap;
  final bool accent;

  const _SpecialKey({
    required this.label,
    required this.keyName,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Consumer<RemoteMouseProvider>(
        builder: (context, provider, _) {
          final isEnabled =
              provider.connectionState == app_state.ConnectionState.connected;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? () => onTap(keyName) : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: accent
                      ? AppColors.primary.withValues(alpha: isEnabled ? 0.2 : 0.08)
                      : AppColors.surfaceLight.withValues(alpha: isEnabled ? 0.8 : 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accent
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.surfaceBright.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: accent
                          ? (isEnabled ? AppColors.primaryLight : AppColors.textTertiary)
                          : (isEnabled ? AppColors.textPrimary : AppColors.textTertiary),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Arrow Key Button ──

class _ArrowKey extends StatelessWidget {
  final String label;
  final String keyName;
  final void Function(String) onTap;

  const _ArrowKey({
    required this.label,
    required this.keyName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RemoteMouseProvider>(
      builder: (context, provider, _) {
        final isEnabled =
            provider.connectionState == app_state.ConnectionState.connected;
        return SizedBox(
          width: 50,
          height: 50,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isEnabled ? () => onTap(keyName) : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: isEnabled ? 0.8 : 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.surfaceBright.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isEnabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}