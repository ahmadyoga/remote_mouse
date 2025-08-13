import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../providers/remote_mouse_provider.dart';
import '../models/device_info.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;
  String? _scannedData;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final permission = await Permission.camera.request();
    if (permission != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan QR codes'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () async {
              await controller?.toggleFlash();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.white,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_scannedData != null)
                    Text(
                      'Scanned: $_scannedData',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Connecting...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  if (!_isProcessing && _scannedData == null)
                    const Text(
                      'Point camera at QR code to scan',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });

    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing && scanData.code != null) {
        _handleQRCode(scanData.code!);
      }
    });
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _scannedData = qrData;
    });

    // Pause camera while processing
    await controller?.pauseCamera();

    try {
      // Parse the QR code data (expected format: "ip:port")
      final parts = qrData.split(':');
      if (parts.length != 2) {
        throw const FormatException(
            'Invalid QR code format. Expected format: ip:port');
      }

      final ip = parts[0].trim();
      final portStr = parts[1].trim();
      final port = int.parse(portStr);

      // Validate IP format (basic validation)
      final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
      if (!ipRegex.hasMatch(ip)) {
        throw const FormatException('Invalid IP address format');
      }

      // Validate each IP octet
      final octets = ip.split('.');
      for (final octet in octets) {
        final value = int.parse(octet);
        if (value < 0 || value > 255) {
          throw const FormatException(
              'Invalid IP address: octets must be 0-255');
        }
      }

      // Validate port range
      if (port < 1 || port > 65535) {
        throw const FormatException('Invalid port number: must be 1-65535');
      }

      // Create device info and attempt connection
      final device = DeviceInfo(
        name: 'QR Scanned Device ($ip)',
        ip: ip,
        port: port,
      );

      final provider = Provider.of<RemoteMouseProvider>(context, listen: false);
      await provider.connectToDevice(device);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully connected to $ip:$port'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Connection failed';
        if (e is FormatException) {
          errorMessage = e.message;
        } else if (e.toString().contains('SocketException')) {
          errorMessage =
              'Cannot reach the server. Check if it\'s running and on the same network.';
        } else {
          errorMessage = 'Connection failed: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Resume camera after a delay
        Future.delayed(const Duration(seconds: 2), () async {
          if (mounted) {
            setState(() {
              _scannedData = null;
            });
            await controller?.resumeCamera();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
