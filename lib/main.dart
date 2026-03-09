import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:remote_mouse/screens/desktop_screen.dart';
import 'package:remote_mouse/theme/app_theme.dart';
import 'providers/remote_mouse_provider.dart';
import 'screens/touchpad_screen.dart';
import 'models/app_state.dart' as app_state;

void main() {
  runApp(const RemoteMouseApp());
}

class RemoteMouseApp extends StatelessWidget {
  const RemoteMouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RemoteMouseProvider(),
      child: MaterialApp(
        title: 'Remote Mouse',
        theme: AppTheme.darkTheme,
        home: const AppModeSelector(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class AppModeSelector extends StatelessWidget {
  const AppModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    if (isDesktop) {
      return const DesktopScreen();
    } else if (isMobile) {
      return const MobileApp();
    } else {
      return const ModeSelectionScreen();
    }
  }
}

class MobileApp extends StatefulWidget {
  const MobileApp({super.key});

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
      provider.initialize(mode: app_state.AppMode.mobile);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const TouchpadScreen();
  }
}

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              Color(0xFF101820),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset('assets/images/icon.png'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Remote Mouse',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose your mode',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _ModeCard(
                    icon: Icons.phone_android,
                    title: 'Mobile',
                    subtitle: 'Use as touchpad controller',
                    onTap: () =>
                        _selectMode(context, app_state.AppMode.mobile),
                  ),
                  const SizedBox(height: 16),
                  _ModeCard(
                    icon: Icons.computer,
                    title: 'Desktop',
                    subtitle: 'Run as mouse server',
                    onTap: () =>
                        _selectMode(context, app_state.AppMode.desktop),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectMode(BuildContext context, app_state.AppMode mode) {
    final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
    provider.initialize(mode: mode);

    if (mode == app_state.AppMode.mobile) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TouchpadScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DesktopScreen()),
      );
    }
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: glassDecoration(opacity: 0.06),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryLight, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textTertiary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
