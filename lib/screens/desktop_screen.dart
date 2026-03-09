import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart' as app_state;
import '../theme/app_theme.dart';

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
      final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
      await provider.initialize(mode: app_state.AppMode.desktop);
      await provider.startServer();
      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Desktop initialization error: $e');
    }
  }

  Future<void> _getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      setState(() => _localIpAddress = wifiIP);
    } catch (e) {
      debugPrint('Error getting IP address: $e');
      setState(() => _localIpAddress = 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Starting server...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/icon.png', width: 28, height: 28),
            const SizedBox(width: 10),
            const Text('Remote Mouse Server'),
          ],
        ),
      ),
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Server Status Card ──
                _DesktopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: (provider.isServerRunning
                                      ? AppColors.connected
                                      : AppColors.error)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              provider.isServerRunning
                                  ? Icons.play_circle_fill
                                  : Icons.stop_circle,
                              color: provider.isServerRunning
                                  ? AppColors.connected
                                  : AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Server Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                provider.isServerRunning
                                    ? 'Running on port ${provider.serverPort}'
                                    : 'Stopped',
                                style: const TextStyle(
                                  color: AppColors.textTertiary,
                                  fontSize: 13,
                                ),
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
                              size: 20,
                            ),
                            label: Text(
                              provider.isServerRunning
                                  ? 'Stop Server'
                                  : 'Start Server',
                            ),
                            style: provider.isServerRunning
                                ? ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.error,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => _showPortDialog(context, provider),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('Port'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Connection Status Card ──
                _DesktopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color:
                                  _getConnectionColor(provider.connectionState),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getConnectionColor(
                                          provider.connectionState)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _getConnectionText(provider.connectionState),
                            style: TextStyle(
                              color:
                                  _getConnectionColor(provider.connectionState),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (provider.connectedDevice != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.connected.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.computer,
                                  color: AppColors.connected, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                provider.connectedDevice!.name,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── QR Code Card ──
                if (provider.isServerRunning && _localIpAddress != null)
                  _DesktopCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Connect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Scan this QR code with the mobile app',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: '$_localIpAddress:${provider.serverPort}',
                              version: QrVersions.auto,
                              size: 160.0,
                              backgroundColor: Colors.white,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.roundedOuter,
                                color: const Color(0xFF0D1117),
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.roundedOuter,
                                color: const Color(0xFF0D1117),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_localIpAddress:${provider.serverPort}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // ── Instructions Card ──
                const _DesktopCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How to Connect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),
                      _InstructionStep(
                          number: 1, text: 'Ensure the server is running'),
                      _InstructionStep(
                          number: 2, text: 'Open Remote Mouse on your phone'),
                      _InstructionStep(
                          number: 3,
                          text: 'Scan the QR code or enter IP manually'),
                      _InstructionStep(
                        number: 4,
                        text: 'Both devices must be on the same network',
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                // ── Error Card ──
                if (provider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            onPressed: provider.clearError,
                            icon: const Icon(Icons.close,
                                color: AppColors.error, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getConnectionColor(app_state.ConnectionState state) {
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
        title: const Row(
          children: [
            Icon(Icons.settings, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Server Port'),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Port Number',
            hintText: '1978',
            prefixIcon: Icon(Icons.tag, size: 20),
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

// ── Desktop Card ──

class _DesktopCard extends StatelessWidget {
  final Widget child;
  const _DesktopCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: glassDecoration(opacity: 0.05),
      child: child,
    );
  }
}

// ── Instruction Step ──

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;
  final bool isLast;

  const _InstructionStep({
    required this.number,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
