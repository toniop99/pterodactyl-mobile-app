import 'dart:async';
import 'package:dartactyl/dartactyl.dart';
import 'package:dartactyl/websocket.dart';

/// Pterodactyl WebSocket Service
/// Handles real-time console log streaming via WebSocket
class PterodactylWebSocketService {
  final String baseUrl;
  final String apiKey;

  ServerWebsocket? _serverWebsocket;

  StreamController<ConsoleMessage>? _messageController;
  StreamController<WebSocketState>? _stateController;

  WebSocketState _lastState = WebSocketState.disconnected;

  Stream<ConsoleMessage> get messageStream =>
      _messageController?.stream ?? const Stream.empty();
  Stream<WebSocketState> get stateStream =>
      _stateController?.stream ?? const Stream.empty();

  bool get isConnected {
    if (_lastState == WebSocketState.connected ||
        _lastState == WebSocketState.authenticated) {
      return true;
    }
    return false;
  }

  PterodactylWebSocketService({
    required this.baseUrl,
    required this.apiKey,
  });

  /// Connect to WebSocket for server console logs
  Future<void> connect({
    required String serverIdentifier,
  }) async {
    try {
      // Close existing connection if any
      await disconnect();

      _messageController = StreamController<ConsoleMessage>.broadcast();
      _stateController = StreamController<WebSocketState>.broadcast();

      final client = PteroClient.generate(url: baseUrl, apiKey: apiKey);
      
      _serverWebsocket = ServerWebsocket(
        client: client, 
        serverId: serverIdentifier,
        autoConnect: true,
        onConnectionError: (error, stackTrace) {
          print('❌ WebSocket Connection Error: $error');
          print('StackTrace: $stackTrace');
          _updateWebsocketState(WebSocketState.error);
        },
      );

      _serverWebsocket!.connectionState.listen((event) {
        print('🔄 WebSocket Connection State Changed: $event');
        switch (event) {
          case ConnectionState.connected:
            _updateWebsocketState(WebSocketState.connected);
            break;
          case ConnectionState.disconnected:
            _updateWebsocketState(WebSocketState.disconnected);
            break;
          case ConnectionState.connecting:
            _updateWebsocketState(WebSocketState.connecting);
            break;
          case ConnectionState.authenticating:
            _updateWebsocketState(WebSocketState.authenticated);
            break;
          case ConnectionState.closed:
            _updateWebsocketState(WebSocketState.disconnected);
            break;
        }
      });

      // print('✅ WebSocket Connected to: $serverIdentifier');
    

      // _serverWebsocket!.stats.listen((event) {
      //     print(event.toString());
          
      //     _messageController?.add(ConsoleMessage(
      //       message: event.toString(),
      //       timestamp: DateTime.now(),
      //       type: ConsoleMessageType.system,
      //     ));
      // });

      // _serverWebsocket!.powerState.listen((event) {
      //   print('Power State Changed: $event');
        
      //   _messageController?.add(ConsoleMessage(
      //     message: 'Power State Changed: $event',
      //     timestamp: DateTime.now(),
      //     type: ConsoleMessageType.system,
      //   ));
      // });
      
      _serverWebsocket!.logs.listen((event) {
        print('Log Received: $event');
        
        _messageController?.add(ConsoleMessage(
          message: event.message,
          timestamp: DateTime.now(),
          type: _detectMessageType(event),
        ));
      });


      
    } catch (e) {
      print('❌ WebSocket Connection Failed: $e');
      _updateWebsocketState(WebSocketState.error);
      rethrow;
    }
  }

  void _updateWebsocketState(WebSocketState newState) {
    if (_lastState == newState) return; // Do not emit if state is the same
    
    _lastState = newState;
    _stateController?.add(newState);
  }

  /// Send command to server
  void sendCommand(String command) {
    if (!isConnected || _serverWebsocket == null) {
      throw Exception('WebSocket not connected');
    }

    _serverWebsocket!.sendCommand(command);
  }

  /// Request server logs (historical)
  void requestLogs() {
    if (!isConnected || _serverWebsocket == null) {
      throw Exception('WebSocket not connected');
    }

    _serverWebsocket!.requestLogs();
  }

  /// Subscribe to server statistics
  void subscribeToStats() {
    if (!isConnected || _serverWebsocket == null) {
      throw Exception('WebSocket not connected');
    }

    _serverWebsocket!.requestStats();
  }

  /// Detect message type from content
  ConsoleMessageType _detectMessageType(WebsocketLog event) {
    final message = event.message.toLowerCase();

    if (event is DaemonMessage) {
      if (message.contains('error') || message.contains('failed')) {
        return ConsoleMessageType.error;
      } else if (message.contains('warning')) {
        return ConsoleMessageType.warning;
      } else if (message.contains('player')) {
        return ConsoleMessageType.player;
      } else if (message.contains('system')) {
        return ConsoleMessageType.system;
      }
    }

    if (message.contains('error') ||
        message.contains('exception') ||
        message.contains('failed')) {
      return ConsoleMessageType.error;
    }

    if (message.contains('warn')) {
      return ConsoleMessageType.warning;
    }

    if (message.contains('joined') ||
        message.contains('left') ||
        message.contains('player')) {
      return ConsoleMessageType.player;
    }

    if (message.contains('started') ||
        message.contains('stopped') ||
        message.contains('loading') ||
        message.contains('autosave')) {
      return ConsoleMessageType.system;
    }

    return ConsoleMessageType.info;
  }

  /// Disconnect WebSocket
  Future<void> disconnect() async {
    print('🔌 Disconnecting WebSocket...');

    await _serverWebsocket?.disconnect();
    _serverWebsocket = null;

    await _messageController?.close();
    _messageController = null;

    await _stateController?.close();
    _stateController = null;

    _lastState = WebSocketState.disconnected;
  }

  /// Dispose service
  void dispose() {
    disconnect();
  }
}

/// WebSocket connection states
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  authenticated,
  error,
  tokenExpiring,
}

/// Console message model
class ConsoleMessage {
  final String message;
  final DateTime timestamp;
  final ConsoleMessageType type;

  ConsoleMessage({
    required this.message,
    required this.timestamp,
    required this.type,
  });

  String get timeFormatted {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Console message types
enum ConsoleMessageType {
  info,
  warning,
  error,
  system,
  player,
}
