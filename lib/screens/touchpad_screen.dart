import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart' as app_state;
import '../theme/app_theme.dart';
import 'settings_screen.dart';
import 'qr_scanner_screen.dart';
import 'keyboard_screen.dart';

class TouchpadScreen extends StatelessWidget {
  const TouchpadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // ── Gradient background with subtle grid ──
              Positioned.fill(
                child: Container(
                  decoration: touchpadGradient(),
                  child: CustomPaint(
                    painter: _GridPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),

              // ── Main touchpad gesture area ──
              Positioned.fill(
                child: GestureDetector(
                  onTap: provider.onTap,
                  onLongPress: provider.onLongPress,
                  onScaleStart: provider.onScaleStart,
                  onScaleUpdate: provider.onScaleUpdate,
                  onScaleEnd: provider.onScaleEnd,
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: provider.connectionState ==
                                app_state.ConnectionState.connected
                            ? 0.15
                            : 0.35,
                        duration: const Duration(milliseconds: 400),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 48,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              provider.connectionState ==
                                      app_state.ConnectionState.connected
                                  ? 'Move to control'
                                  : 'Connect to start',
                              style: TextStyle(
                                color:
                                    AppColors.textSecondary.withValues(alpha: 0.6),
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Top bar ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        // Connection status badge
                        _buildConnectionBadge(provider),
                        const Spacer(),
                        // Toolbar buttons
                        _ToolbarContainer(
                          children: [
                            if (provider.connectionState ==
                                app_state.ConnectionState.disconnected)
                              _ToolbarButton(
                                icon: Icons.qr_code_scanner,
                                tooltip: 'Scan QR',
                                onTap: () => _navigateToQRScanner(context),
                              ),
                            _ToolbarButton(
                              icon: Icons.keyboard_outlined,
                              tooltip: 'Keyboard',
                              onTap: () => _navigateToKeyboard(context),
                            ),
                            _ToolbarButton(
                              icon: Icons.wifi,
                              tooltip: 'Connect',
                              onTap: () =>
                                  _showConnectionDialog(context, provider),
                            ),
                            _ToolbarButton(
                              icon: Icons.settings_outlined,
                              tooltip: 'Settings',
                              onTap: () => _navigateToSettings(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Click buttons (right side) ──
              Positioned(
                bottom: 100,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      label: 'L',
                      heroTag: 'left_click',
                      onPressed: () => provider.simulateClick('left'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      label: 'R',
                      heroTag: 'right_click',
                      onPressed: () => provider.simulateClick('right'),
                    ),
                  ],
                ),
              ),

              // ── Scroll buttons (left side) ──
              Positioned(
                bottom: 100,
                left: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionButton(
                      icon: Icons.keyboard_arrow_up,
                      heroTag: 'scroll_up',
                      onPressed: () => provider.simulateScroll('up'),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.keyboard_arrow_down,
                      heroTag: 'scroll_down',
                      onPressed: () => provider.simulateScroll('down'),
                    ),
                  ],
                ),
              ),

              // ── Hint card when disconnected ──
              if (provider.connectionState ==
                  app_state.ConnectionState.disconnected)
                Positioned(
                  bottom: 32,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: glassDecoration(opacity: 0.06),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary.withValues(alpha: 0.7),
                            size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Tap the Wi-Fi icon or scan a QR code to connect to your desktop.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ──

  Widget _buildConnectionBadge(RemoteMouseProvider provider) {
    final color = _getConnectionColor(provider.connectionState);
    final icon = _getConnectionIcon(provider.connectionState);
    final text = _getConnectionText(provider.connectionState);
    final subtitle = (provider.connectionState ==
                app_state.ConnectionState.connected &&
            provider.connectedDevice != null)
        ? '${provider.connectedDevice!.ip}:${provider.connectedDevice!.port}'
        : null;

    return connectionBadge(
      label: text,
      color: color,
      icon: icon,
      subtitle: subtitle,
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

  void _showConnectionDialog(
      BuildContext context, RemoteMouseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => ConnectionDialog(provider: provider),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _navigateToQRScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
  }

  void _navigateToKeyboard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const KeyboardScreen()),
    );
  }
}

// ── Subtle grid painter for touchpad texture ──

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceBright.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Glassmorphism toolbar container ──

class _ToolbarContainer extends StatelessWidget {
  final List<Widget> children;
  const _ToolbarContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: glassDecoration(opacity: 0.08, borderRadius: 14),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Themed floating action button ──

class _ActionButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final String heroTag;
  final VoidCallback onPressed;

  const _ActionButton({
    this.label,
    this.icon,
    required this.heroTag,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        heroTag: heroTag,
        mini: true,
        elevation: 2,
        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        onPressed: onPressed,
        child: icon != null
            ? Icon(icon, color: AppColors.primaryLight, size: 22)
            : Text(
                label ?? '',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

// ── Connection Dialog ──

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
    setState(() => _isDiscovering = true);
    await widget.provider.startDiscovery();
    setState(() => _isDiscovering = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.wifi, color: AppColors.primary, size: 24),
          SizedBox(width: 10),
          Text('Connect to Desktop'),
        ],
      ),
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
                    'Discovered Devices',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.provider.discoveredDevices.map(
                    (device) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: glassDecoration(opacity: 0.05, borderRadius: 12),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.computer,
                              color: AppColors.primary, size: 20),
                        ),
                        title: Text(device.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text('${device.ip}:${device.port}',
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 12)),
                        onTap: () {
                          widget.provider.connectToDevice(device);
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                ],
              ),

            // Manual connection
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manual Connection',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                prefixIcon: Icon(Icons.dns_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '1978',
                prefixIcon: Icon(Icons.tag, size: 20),
              ),
              keyboardType: TextInputType.number,
            ),

            if (widget.provider.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.provider.errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _isDiscovering ? null : _startDiscovery,
          icon: _isDiscovering
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh, size: 18),
          label: const Text('Scan'),
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
