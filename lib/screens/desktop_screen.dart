import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart' as app_state;

class DesktopScreen extends StatefulWidget {
  const DesktopScreen({super.key});

  @override
  State<DesktopScreen> createState() => _DesktopScreenState();
}

class _DesktopScreenState extends State<DesktopScreen> {
  bool _isInitialized = false;
  String? _localIpAddress;

  @override
  void initState() {
    super.initState();
    _initializeDesktop();
    _getLocalIpAddress();
  }

  Future<void> _initializeDesktop() async {
    try {
      // Initialize provider only - don't auto-start server
      final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
      await provider.initialize(mode: app_state.AppMode.desktop);
      
      setState(() {
        _isInitialized = true;
      });
      
      // Optionally auto-start server after a brief delay to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          provider.startServer();
        }
      });
    } catch (e) {
      print('Desktop initialization error: $e');
      setState(() {
        _isInitialized = true; // Show UI even if there's an error
      });
    }
  }

  Future<void> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      setState(() {
        _localIpAddress = wifiIP;
      });
    } catch (e) {
      print('Error getting IP address: $e');
      setState(() {
        _localIpAddress = 'Unknown';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Mouse Server'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                provider.isServerRunning
                                    ? Icons.play_circle_fill
                                    : Icons.stop_circle,
                                color: provider.isServerRunning
                                    ? Colors.green
                                    : Colors.red,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Server Status',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  Text(
                                    provider.isServerRunning
                                        ? 'Running on port ${provider.serverPort}'
                                        : 'Stopped',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: provider.isServerRunning
                                    ? () => provider.stopServer()
                                    : () => provider.startServer(),
                                icon: Icon(
                                  provider.isServerRunning
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                                label: Text(
                                  provider.isServerRunning
                                      ? 'Stop Server'
                                      : 'Start Server',
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _showPortDialog(context, provider),
                                icon: const Icon(Icons.settings),
                                label: const Text('Port Settings'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Connection Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Connection Status',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _getConnectionIcon(provider.connectionState),
                                color: _getConnectionColor(
                                    provider.connectionState),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  _getConnectionText(provider.connectionState)),
                            ],
                          ),
                          if (provider.connectedDevice != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Connected to: ${provider.connectedDevice!.name}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // QR Code Card
                  if (provider.isServerRunning && _localIpAddress != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quick Connect',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan this QR code with the mobile app to connect instantly',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: QrImageView(
                                  data:
                                      '$_localIpAddress:${provider.serverPort}',
                                  version: QrVersions.auto,
                                  size: 150.0,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                '$_localIpAddress:${provider.serverPort}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Instructions Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructions',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Make sure the server is running\n'
                            '2. Install the Remote Mouse app on your mobile device\n'
                            '3. Connect to this computer using device discovery or manual IP entry\n'
                            '4. Use your mobile device as a touchpad!\n\n'
                            'Make sure both devices are on the same network.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  provider.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                              IconButton(
                                onPressed: provider.clearError,
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
        return 'Waiting for connection';
    }
  }

  void _showPortDialog(BuildContext context, RemoteMouseProvider provider) {
    final controller =
        TextEditingController(text: provider.serverPort.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Port'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Port Number',
            hintText: '1978',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final port = int.tryParse(controller.text);
              if (port != null && port > 0 && port < 65536) {
                provider.setServerPort(port);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Port updated. Restart server to apply changes.'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
