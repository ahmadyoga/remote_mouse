import 'dart:io';
import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import '../models/device_info.dart';
import '../models/app_state.dart';

class DeviceDiscoveryService {
  static final DeviceDiscoveryService _instance =
      DeviceDiscoveryService._internal();
  factory DeviceDiscoveryService() => _instance;
  DeviceDiscoveryService._internal();

  MDnsClient? _mdnsClient;
  StreamController<DeviceInfo>? _deviceController;
  Timer? _discoveryTimer;

  Stream<DeviceInfo> get deviceStream => _deviceController!.stream;

  Future<void> startDiscovery() async {
    try {
      _deviceController = StreamController<DeviceInfo>.broadcast();
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();

      // Start discovery with timeout
      _discoveryTimer = Timer(AppConstants.discoveryTimeout, () {
        stopDiscovery();
      });

      await for (final PtrResourceRecord ptr in _mdnsClient!
          .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(AppConstants.serviceName))) {
        await for (final SrvResourceRecord srv in _mdnsClient!
            .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName))) {
          final deviceInfo = DeviceInfo(
            name: ptr.domainName
                .replaceAll('.${AppConstants.serviceName}.local', ''),
            ip: srv.target,
            port: srv.port,
          );

          _deviceController!.add(deviceInfo);
        }
      }
    } catch (e) {
      print('Discovery error: $e');
    }
  }

  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _mdnsClient?.stop();
    _mdnsClient = null;
    await _deviceController?.close();
    _deviceController = null;
  }

  Future<void> announceService(
      {required int port, required String deviceName}) async {
    try {
      _mdnsClient = MDnsClient();
      await _mdnsClient!.start();

      final String hostname =
          '${deviceName.replaceAll(' ', '-')}.${AppConstants.serviceName}.local';

      // Get local IP address
      final interfaces = await NetworkInterface.list();
      String? localIp;

      for (final interface in interfaces) {
        if (!interface.name.contains('lo') && interface.addresses.isNotEmpty) {
          for (final addr in interface.addresses) {
            if (addr.type == InternetAddressType.IPv4) {
              localIp = addr.address;
              break;
            }
          }
          if (localIp != null) break;
        }
      }

      if (localIp != null) {
        // Announce service
        await _mdnsClient!.start();

        print('Announced service: $hostname on $localIp:$port');
      }
    } catch (e) {
      print('Service announcement error: $e');
    }
  }

  void dispose() {
    stopDiscovery();
  }
}
