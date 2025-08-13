import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:developer' as developer;
import '../models/mouse_event.dart';
import '../models/device_info.dart';
import '../models/app_state.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  ServerSocket? _serverSocket;
  Socket? _clientSocket;
  StreamController<MouseEvent>? _eventController;
  StreamController<ConnectionState>? _connectionController;
  Timer? _heartbeatTimer;

  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  Stream<MouseEvent> get eventStream {
    _eventController ??= StreamController<MouseEvent>.broadcast();
    return _eventController!.stream;
  }

  Stream<ConnectionState> get connectionStream {
    _connectionController ??= StreamController<ConnectionState>.broadcast();
    return _connectionController!.stream;
  }

  Future<void> startServer({required int port}) async {
    try {
      _eventController ??= StreamController<MouseEvent>.broadcast();
      _connectionController ??= StreamController<ConnectionState>.broadcast();

      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _updateConnectionState(ConnectionState.disconnected);

      print('TCP Server started on port $port');

      _serverSocket!.listen((Socket client) {
        print('Client connected: ${client.remoteAddress.address}');
        _handleClientConnection(client);
      });
    } catch (e) {
      print('Server start error: $e');
      _updateConnectionState(ConnectionState.error);
    }
  }

  Future<void> connectToServer(DeviceInfo device) async {
    try {
      _eventController ??= StreamController<MouseEvent>.broadcast();
      _connectionController ??= StreamController<ConnectionState>.broadcast();

      _updateConnectionState(ConnectionState.connecting);

      _clientSocket = await Socket.connect(
        device.ip,
        device.port,
        timeout: AppConstants.connectionTimeout,
      );

      _updateConnectionState(ConnectionState.connected);
      _startHeartbeat();

      print('Connected to server: ${device.ip}:${device.port}');

      _clientSocket!.listen(
        _handleServerData,
        onDone: () {
          print('Server disconnected');
          _updateConnectionState(ConnectionState.disconnected);
          _stopHeartbeat();
        },
        onError: (error) {
          print('Connection error: $error');
          _updateConnectionState(ConnectionState.error);
          _stopHeartbeat();
        },
      );
    } catch (e) {
      print('Connection failed: $e');
      _updateConnectionState(ConnectionState.error);
    }
  }

  void _handleClientConnection(Socket client) {
    _clientSocket = client;
    _updateConnectionState(ConnectionState.connected);
    _startHeartbeat();

    client.listen(
      _handleClientData,
      onDone: () {
        print('Client disconnected');
        _updateConnectionState(ConnectionState.disconnected);
        _stopHeartbeat();
      },
      onError: (error) {
        print('Client error: $error');
        _updateConnectionState(ConnectionState.error);
        _stopHeartbeat();
      },
    );
  }

  void _handleClientData(List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final jsonData = json.decode(jsonString);
      final mouseEvent = MouseEvent.fromJson(jsonData);
      print('Parsed mouse event: $mouseEvent');
      print('Adding event to stream controller...');
      _eventController!.add(mouseEvent);
      print('Event added to stream');
    } catch (e) {
      print('Data parsing error: $e');
    }
  }

  void _handleServerData(List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      final jsonData = json.decode(jsonString);

      // Handle heartbeat and other server messages
      if (jsonData['type'] == 'heartbeat') {
        sendHeartbeat();
      }
    } catch (e) {
      print('Server data parsing error: $e');
    }
  }

  Future<void> sendMouseEvent(MouseEvent event) async {
    if (_clientSocket != null &&
        _connectionState == ConnectionState.connected) {
      try {
        final jsonString = json.encode(event.toJson());
        _clientSocket!.add(utf8.encode(jsonString));
      } catch (e) {
        developer.log('Send error: $e');
        _updateConnectionState(ConnectionState.error);
      }
    }
  }

  void sendHeartbeat() {
    if (_clientSocket != null &&
        _connectionState == ConnectionState.connected) {
      try {
        final heartbeat = json.encode({
          'type': 'heartbeat',
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
        _clientSocket!.write(heartbeat);
      } catch (e) {
        print('Heartbeat error: $e');
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(AppConstants.heartbeatInterval, (timer) {
      sendHeartbeat();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _updateConnectionState(ConnectionState newState) {
    _connectionState = newState;
    _connectionController?.add(newState);
  }

  Future<void> stopServer() async {
    await _serverSocket?.close();
    _serverSocket = null;
    _updateConnectionState(ConnectionState.disconnected);
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    await _clientSocket?.close();
    _clientSocket = null;
    _updateConnectionState(ConnectionState.disconnected);
  }

  void dispose() {
    stopServer();
    disconnect();
    _eventController?.close();
    _connectionController?.close();
  }
}
