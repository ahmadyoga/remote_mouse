import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart';
import 'qr_scanner_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // QR Code Scanner (only show if not connected)
              if (provider.connectedDevice == null)
                _buildSettingCard(
                  title: 'Quick Connect',
                  subtitle: 'Scan QR code from desktop to connect instantly',
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      foregroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ),

              if (provider.connectedDevice == null) const SizedBox(height: 16),

              // Mouse Sensitivity
              _buildSettingCard(
                title: 'Mouse Sensitivity',
                subtitle: 'Adjust cursor movement sensitivity',
                child: Column(
                  children: [
                    Slider(
                      value: provider.appSettings.mouseSensitivity,
                      min: 0.1,
                      max: 50.0,
                      divisions: 49,
                      label: provider.appSettings.mouseSensitivity
                          .toStringAsFixed(1),
                      onChanged: (value) {
                        provider.updateMouseSensitivity(value);
                      },
                    ),
                    Text(
                      'Current: ${provider.appSettings.mouseSensitivity.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Scroll Sensitivity
              _buildSettingCard(
                title: 'Scroll Sensitivity',
                subtitle: 'Adjust two-finger scroll speed',
                child: Column(
                  children: [
                    Slider(
                      value: provider.appSettings.scrollSensitivity,
                      min: 0.1,
                      max: 5.0,
                      divisions: 49,
                      label: provider.appSettings.scrollSensitivity
                          .toStringAsFixed(1),
                      onChanged: (value) {
                        provider.updateScrollSensitivity(value);
                      },
                    ),
                    Text(
                      'Current: ${provider.appSettings.scrollSensitivity.toStringAsFixed(1)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reverse Scroll
              _buildSettingCard(
                title: 'Reverse Scroll',
                subtitle: 'Enable natural/reverse scrolling like trackpads',
                child: SwitchListTile(
                  value: provider.appSettings.reverseScroll,
                  onChanged: (value) {
                    provider.updateReverseScroll(value);
                  },
                  title: Text(
                    provider.appSettings.reverseScroll
                        ? 'Natural'
                        : 'Traditional',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    provider.appSettings.reverseScroll
                        ? 'Scroll content follows finger movement'
                        : 'Scroll content moves opposite to finger',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  activeColor: Colors.blue,
                  contentPadding: EdgeInsets.zero,
                ),
              ),

              const SizedBox(height: 16),

              // Double Click Threshold
              _buildSettingCard(
                title: 'Double Click Speed',
                subtitle: 'Time window for double-tap detection',
                child: Column(
                  children: [
                    Slider(
                      value: provider.appSettings.doubleClickThreshold,
                      min: 100,
                      max: 1000,
                      divisions: 18,
                      label:
                          '${provider.appSettings.doubleClickThreshold.round()}ms',
                      onChanged: (value) {
                        provider.updateDoubleClickThreshold(value);
                      },
                    ),
                    Text(
                      'Current: ${provider.appSettings.doubleClickThreshold.round()}ms',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reset to defaults
              _buildSettingCard(
                title: 'Reset Settings',
                subtitle: 'Restore default values',
                child: ElevatedButton(
                  onPressed: () {
                    _showResetDialog(context, provider);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.2),
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Reset to Defaults'),
                ),
              ),

              const SizedBox(height: 24),

              // Connection Info
              if (provider.connectedDevice != null)
                _buildSettingCard(
                  title: 'Connection Info',
                  subtitle: 'Current connection details',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.computer, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            provider.connectedDevice!.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.network_check,
                              color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            '${provider.connectedDevice!.ip}:${provider.connectedDevice!.port}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          provider.disconnect();
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Disconnect'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.withOpacity(0.2),
                          foregroundColor: Colors.orange,
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

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, RemoteMouseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'Are you sure you want to reset all settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateSettings(AppSettings());
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
