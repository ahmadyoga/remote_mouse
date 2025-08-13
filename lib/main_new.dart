import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
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
    // Determine mode based on platform
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    if (isDesktop) {
      return const DesktopApp();
    } else if (isMobile) {
      return const MobileApp();
    } else {
      // Fallback - show selection screen
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

class DesktopApp extends StatefulWidget {
  const DesktopApp({super.key});

  @override
  State<DesktopApp> createState() => _DesktopAppState();
}

class _DesktopAppState extends State<DesktopApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Mouse Server'),
      ),
      body: Consumer<RemoteMouseProvider>(
        builder: (context, provider, child) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.computer,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Remote Mouse Server',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.isServerRunning
                        ? 'Server running on port ${provider.serverPort}'
                        : 'Server stopped',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: provider.isServerRunning
                        ? () => provider.stopServer()
                        : () => provider.startServer(),
                    icon: Icon(
                      provider.isServerRunning ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      provider.isServerRunning ? 'Stop Server' : 'Start Server',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Connect from your mobile device using the Remote Mouse app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
      provider.initialize(mode: app_state.AppMode.desktop);
    });
  }
}

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remote Mouse'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mouse,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 32),
              const Text(
                'Remote Mouse',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose your mode:',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _selectMode(context, app_state.AppMode.mobile),
                  icon: const Icon(Icons.phone_android),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Mobile (Touchpad)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _selectMode(context, app_state.AppMode.desktop),
                  icon: const Icon(Icons.computer),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Desktop (Server)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
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
        MaterialPageRoute(builder: (context) => const DesktopApp()),
      );
    }
  }
}
