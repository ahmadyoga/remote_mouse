import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/app_state.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── QR Code Scanner ──
              if (provider.connectedDevice == null) ...[
                _SettingCard(
                  icon: Icons.qr_code_scanner,
                  title: 'Quick Connect',
                  subtitle: 'Scan QR code from desktop to connect instantly',
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const QRScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text('Scan QR Code'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Section: Controls ──
              const _SectionHeader(title: 'Controls'),
              const SizedBox(height: 8),

              // Mouse Sensitivity
              _SettingCard(
                icon: Icons.mouse_outlined,
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
                    _ValueLabel(
                      value: provider.appSettings.mouseSensitivity
                          .toStringAsFixed(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Scroll Sensitivity
              _SettingCard(
                icon: Icons.swap_vert,
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
                    _ValueLabel(
                      value: provider.appSettings.scrollSensitivity
                          .toStringAsFixed(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Reverse Scroll
              _SettingCard(
                icon: Icons.sync_alt,
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
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    provider.appSettings.reverseScroll
                        ? 'Scroll content follows finger movement'
                        : 'Scroll content moves opposite to finger',
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 12),

              // Double Click Threshold
              _SettingCard(
                icon: Icons.ads_click,
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
                    _ValueLabel(
                      value:
                          '${provider.appSettings.doubleClickThreshold.round()}ms',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Section: Danger Zone ──
              const _SectionHeader(title: 'Danger Zone'),
              const SizedBox(height: 8),

              _SettingCard(
                icon: Icons.restore,
                title: 'Reset Settings',
                subtitle: 'Restore default values',
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showResetDialog(context, provider),
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Reset to Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Connection Info ──
              if (provider.connectedDevice != null) ...[
                const _SectionHeader(title: 'Connection'),
                const SizedBox(height: 8),
                _SettingCard(
                  icon: Icons.link,
                  title: 'Connection Info',
                  subtitle: 'Currently connected device',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.computer,
                        label: provider.connectedDevice!.name,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.language,
                        label:
                            '${provider.connectedDevice!.ip}:${provider.connectedDevice!.port}',
                        mono: true,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            provider.disconnect();
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.connecting,
                            side: BorderSide(
                                color: AppColors.connecting
                                    .withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, RemoteMouseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Reset Settings'),
          ],
        ),
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
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Setting Card ──

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassDecoration(opacity: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Section Header ──

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Value Label ──

class _ValueLabel extends StatelessWidget {
  final String value;
  const _ValueLabel({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ── Info Row ──

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textTertiary, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}
