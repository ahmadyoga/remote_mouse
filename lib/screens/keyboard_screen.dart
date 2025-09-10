import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart' as app_state;

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
    
    // Auto-focus the text field when the screen opens
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
      // Text was added
      final addedText = currentText.substring(_lastText.length);
      provider.typeText(addedText);
    } else if (currentText.length < _lastText.length) {
      // Text was removed (backspace)
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
          _textController.text = _textController.text.substring(0, _textController.text.length - 1);
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
      case 'up':
      case 'down':
      case 'left':
      case 'right':
        // Arrow keys should be sent as keyboard events, not scroll events
        provider.pressKey(key);
        break;
      default:
        provider.pressKey(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Remote Keyboard'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Connection status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: _getConnectionColor(provider.connectionState),
                child: Row(
                  children: [
                    Icon(
                      _getConnectionIcon(provider.connectionState),
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getConnectionText(provider.connectionState),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (provider.connectedDevice != null) ...[
                      const Spacer(),
                      Text(
                        '${provider.connectedDevice!.ip}:${provider.connectedDevice!.port}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Text input area
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Type here to send text to desktop:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          expands: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Start typing...',
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 18,
                            ),
                          ),
                          enabled: provider.connectionState == app_state.ConnectionState.connected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Special keys
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Special Keys:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // First row of special keys
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpecialKeyButton('Tab', 'tab'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecialKeyButton('Space', 'space'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecialKeyButton('Enter', 'enter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Second row of special keys
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpecialKeyButton('Backspace', 'backspace'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecialKeyButton('Escape', 'escape'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSpecialKeyButton('Clear', 'clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Arrow keys
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildArrowKeyButton('↑', 'up'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildArrowKeyButton('←', 'left'),
                        const SizedBox(width: 8),
                        _buildArrowKeyButton('↓', 'down'),
                        const SizedBox(width: 8),
                        _buildArrowKeyButton('→', 'right'),
                      ],
                    ),
                  ],
                ),
              ),

              // Instructions
              if (provider.connectionState != app_state.ConnectionState.connected)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Connect to a desktop device to use the keyboard',
                          style: TextStyle(color: Colors.orange),
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

  Widget _buildSpecialKeyButton(String label, String key) {
    return Consumer<RemoteMouseProvider>(
      builder: (context, provider, child) {
        final isEnabled = provider.connectionState == app_state.ConnectionState.connected;
        
        return ElevatedButton(
          onPressed: isEnabled ? () {
            if (key == 'clear') {
              _textController.clear();
              _lastText = '';
            } else {
              _handleSpecialKey(key);
            }
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(isEnabled ? 0.2 : 0.1),
            foregroundColor: isEnabled ? Colors.white : Colors.white38,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        );
      },
    );
  }

  Widget _buildArrowKeyButton(String label, String key) {
    return Consumer<RemoteMouseProvider>(
      builder: (context, provider, child) {
        final isEnabled = provider.connectionState == app_state.ConnectionState.connected;
        
        return SizedBox(
          width: 50,
          height: 50,
          child: ElevatedButton(
            onPressed: isEnabled ? () => _handleSpecialKey(key) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(isEnabled ? 0.2 : 0.1),
              foregroundColor: isEnabled ? Colors.white : Colors.white38,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        );
      },
    );
  }

  Color _getConnectionColor(app_state.ConnectionState state) {
    switch (state) {
      case app_state.ConnectionState.connected:
        return Colors.green;
      case app_state.ConnectionState.connecting:
      case app_state.ConnectionState.reconnecting:
        return Colors.orange;
      case app_state.ConnectionState.error:
        return Colors.red;
      case app_state.ConnectionState.disconnected:
        return Colors.grey;
    }
  }

  IconData _getConnectionIcon(app_state.ConnectionState state) {
    switch (state) {
      case app_state.ConnectionState.connected:
        return Icons.wifi;
      case app_state.ConnectionState.connecting:
      case app_state.ConnectionState.reconnecting:
        return Icons.wifi_find;
      case app_state.ConnectionState.error:
        return Icons.wifi_off;
      case app_state.ConnectionState.disconnected:
        return Icons.portable_wifi_off;
    }
  }

  String _getConnectionText(app_state.ConnectionState state) {
    switch (state) {
      case app_state.ConnectionState.connected:
        return 'Connected - Keyboard Active';
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