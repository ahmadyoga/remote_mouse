import 'dart:io';
import 'dart:convert';
import 'dart:async';
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

  // Buffer to accumulate partial data
  String _dataBuffer = '';

  void _handleClientData(List<int> data) {
    try {
      final jsonString = utf8.decode(data);
      print('Received raw data: $jsonString');

      // Add to buffer
      _dataBuffer += jsonString;

      // Process all complete JSON objects in the buffer
      _processBufferedData();
    } catch (e) {
      print('Data parsing error: $e');
    }
  }

  void _processBufferedData() {
    // First try to process newline-delimited messages
    final lines = _dataBuffer.split('\n');

    // Process all complete lines (last line might be incomplete)
    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        try {
          final jsonData = json.decode(line);
          final event = MouseEvent.fromJson(jsonData);
          print('Parsed mouse event: $event');
          _eventController!.add(event);
        } catch (e) {
          print('Error parsing line: $e');
          print('Problematic line: $line');
        }
      }
    }

    // Keep the last incomplete line in buffer
    _dataBuffer = lines.last;

    // If no newlines found, try to parse concatenated JSON objects
    if (lines.length == 1 && _dataBuffer.length > 1000) {
      // Buffer is getting too large, try to parse concatenated JSON
      final events = _parseMultipleJsonObjects(_dataBuffer);

      for (final event in events) {
        print('Parsed mouse event: $event');
        _eventController!.add(event);
      }

      if (events.isNotEmpty) {
        _dataBuffer = _removeProcessedJson(_dataBuffer, events.length);
      }
    }
  }

  List<MouseEvent> _parseMultipleJsonObjects(String jsonString) {
    final events = <MouseEvent>[];
    int startIndex = 0;
    int braceCount = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < jsonString.length; i++) {
      final char = jsonString[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\' && inString) {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;

          if (braceCount == 0) {
            // Found complete JSON object
            final jsonObj = jsonString.substring(startIndex, i + 1);
            try {
              final jsonData = json.decode(jsonObj);
              events.add(MouseEvent.fromJson(jsonData));
              startIndex = i + 1;
            } catch (e) {
              print('Error parsing JSON object: $e');
              print('Problematic JSON: $jsonObj');
            }
          }
        }
      }
    }

    return events;
  }

  String _removeProcessedJson(String buffer, int processedCount) {
    int removedCount = 0;
    int braceCount = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < buffer.length && removedCount < processedCount; i++) {
      final char = buffer[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\' && inString) {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;

          if (braceCount == 0) {
            removedCount++;
            if (removedCount == processedCount) {
              return buffer.substring(i + 1);
            }
          }
        }
      }
    }

    return buffer;
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
        // Add newline delimiter to make parsing easier
        _clientSocket!.write('$jsonString\n');
        await _clientSocket!.flush();
      } catch (e) {
        print('Send error: $e');
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
