import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart' as app_state;
import 'settings_screen.dart';
import 'qr_scanner_screen.dart';
import 'keyboard_screen.dart';

class TouchpadScreen extends StatelessWidget {
  const TouchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Main touchpad area
              Positioned.fill(
                child: GestureDetector(
                  onTap: provider.onTap,
                  onLongPress: provider.onLongPress,
                  onScaleStart: provider.onScaleStart,
                  onScaleUpdate: provider.onScaleUpdate,
                  onScaleEnd: provider.onScaleEnd,
                  child: Container(
                    color: Colors.black,
                    child: const Center(
                      child: Text(
                        'Touchpad Area',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Connection status indicator
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: _buildConnectionStatus(context, provider),
              ),

              // Settings and connection buttons
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // QR Scanner button (only show when disconnected)
                    if (provider.connectionState ==
                        app_state.ConnectionState.disconnected)
                      IconButton(
                        onPressed: () => _navigateToQRScanner(context),
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white54,
                        ),
                      ),
                    // Keyboard button
                    IconButton(
                      onPressed: () => _navigateToKeyboard(context),
                      icon: const Icon(
                        Icons.keyboard,
                        color: Colors.white54,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showConnectionDialog(context, provider),
                      icon: const Icon(
                        Icons.wifi,
                        color: Colors.white54,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _navigateToSettings(context),
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),

              // Floating action buttons
              Positioned(
                bottom: 80,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'left_click',
                      mini: true,
                      backgroundColor: Colors.white24,
                      onPressed: () => provider.simulateClick('left'),
                      child: const Text(
                        'L',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'right_click',
                      mini: true,
                      backgroundColor: Colors.white24,
                      onPressed: () => provider.simulateClick('right'),
                      child: const Text(
                        'R',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

                // Scroll buttons (vertical)
                Positioned(
                  bottom: 80,
                  left: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'scroll_up',
                        mini: true,
                        backgroundColor: Colors.white24,
                        onPressed: () => provider.simulateScroll('up'),
                        child: const Icon(
                          Icons.keyboard_arrow_up,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'scroll_down',
                        mini: true,
                        backgroundColor: Colors.white24,
                        onPressed: () => provider.simulateScroll('down'),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Horizontal scroll buttons
                Positioned(
                  bottom: 150,
                  left: 80,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'scroll_left',
                        mini: true,
                        backgroundColor: Colors.white24,
                        onPressed: () => provider.simulateScroll('left'),
                        child: const Icon(
                          Icons.keyboard_arrow_left,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        heroTag: 'scroll_right',
                        mini: true,
                        backgroundColor: Colors.white24,
                        onPressed: () => provider.simulateScroll('right'),
                        child: const Icon(
                          Icons.keyboard_arrow_right,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),              // Instructions
              if (provider.connectionState ==
                  app_state.ConnectionState.disconnected)
                Positioned(
                  bottom: 40,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tap settings to connect to a desktop device. Once connected, use this area as a touchpad or tap the keyboard icon to type.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
        return 'Connected';
      case app_state.ConnectionState.connecting:
        return 'Connecting';
      case app_state.ConnectionState.reconnecting:
        return 'Reconnecting';
      case app_state.ConnectionState.error:
        return 'Error';
      case app_state.ConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  Widget _buildConnectionStatus(
      BuildContext context, RemoteMouseProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getConnectionColor(provider.connectionState),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getConnectionIcon(provider.connectionState),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _getConnectionText(provider.connectionState),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (provider.connectionState == app_state.ConnectionState.connected &&
              provider.connectedDevice != null)
            Text(
              '${provider.connectedDevice!.ip}:${provider.connectedDevice!.port}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  void _showConnectionDialog(
      BuildContext context, RemoteMouseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ConnectionDialog(provider: provider),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsScreen(),
      ),
    );
  }

  void _navigateToQRScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );
  }

  void _navigateToKeyboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const KeyboardScreen(),
      ),
    );
  }
}

class ConnectionDialog extends StatefulWidget {
  final RemoteMouseProvider provider;

  const ConnectionDialog({
    super.key,
    required this.provider,
  });

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '1978');
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() async {
    setState(() {
      _isDiscovering = true;
    });

    await widget.provider.startDiscovery();

    setState(() {
      _isDiscovering = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect to Desktop'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Discovered devices
            if (widget.provider.discoveredDevices.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Discovered Devices:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...widget.provider.discoveredDevices.map(
                    (device) => ListTile(
                      leading: const Icon(Icons.computer),
                      title: Text(device.name),
                      subtitle: Text('${device.ip}:${device.port}'),
                      onTap: () {
                        widget.provider.connectToDevice(device);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const Divider(),
                ],
              ),

            // Manual connection
            const Text(
              'Manual Connection:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '1978',
              ),
              keyboardType: TextInputType.number,
            ),

            if (widget.provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.provider.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDiscovering ? null : _startDiscovery,
          child: _isDiscovering
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Refresh'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _ipController.text.isNotEmpty
              ? () {
                  final port = int.tryParse(_portController.text) ?? 1978;
                  widget.provider.connectToIP(_ipController.text, port);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Connect'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
