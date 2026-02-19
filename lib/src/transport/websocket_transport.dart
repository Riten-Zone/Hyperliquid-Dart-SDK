/// WebSocket transport layer for Hyperliquid real-time data.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/constants.dart';

/// Connection state of the WebSocket.
enum WsConnectionState {
  disconnected,
  connecting,
  connected,
}

/// WebSocket transport with automatic reconnection and message routing.
class WebSocketTransport {
  final bool isTestnet;
  final Duration pingInterval;
  final Duration reconnectBaseDelay;
  final int maxReconnectAttempts;

  WebSocketChannel? _channel;
  WsConnectionState _state = WsConnectionState.disconnected;
  int _reconnectAttempts = 0;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _intentionalDisconnect = false;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<WsConnectionState> _stateController =
      StreamController<WsConnectionState>.broadcast();

  /// Stream of parsed JSON messages from the WebSocket.
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream of connection state changes.
  Stream<WsConnectionState> get stateChanges => _stateController.stream;

  /// Current connection state.
  WsConnectionState get state => _state;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _state == WsConnectionState.connected;

  WebSocketTransport({
    this.isTestnet = false,
    this.pingInterval = const Duration(seconds: 30),
    this.reconnectBaseDelay = const Duration(seconds: 1),
    this.maxReconnectAttempts = 10,
  });

  /// Connect to the Hyperliquid WebSocket.
  Future<void> connect() async {
    if (_state == WsConnectionState.connected ||
        _state == WsConnectionState.connecting) {
      return;
    }

    _intentionalDisconnect = false;
    _setState(WsConnectionState.connecting);

    try {
      final wsUrl = HyperliquidUrls.wsUrl(isTestnet: isTestnet);
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _setState(WsConnectionState.connected);
      _reconnectAttempts = 0;
      _startPing();

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  /// Disconnect from the WebSocket.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _stopPing();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_channel != null) {
      await _channel!.sink.close();
      _channel = null;
    }

    _setState(WsConnectionState.disconnected);
  }

  /// Send a JSON message through the WebSocket.
  void send(Map<String, dynamic> message) {
    if (_state != WsConnectionState.connected || _channel == null) {
      throw StateError('WebSocket is not connected');
    }
    _channel!.sink.add(jsonEncode(message));
  }

  /// Send a subscription message.
  void subscribe(Map<String, dynamic> subscriptionMessage) {
    send(subscriptionMessage);
  }

  /// Send an unsubscription message.
  void unsubscribe(Map<String, dynamic> subscriptionMessage) {
    final unsub = Map<String, dynamic>.from(subscriptionMessage);
    unsub['method'] = 'unsubscribe';
    send(unsub);
  }

  void _onMessage(dynamic data) {
    try {
      final parsed = jsonDecode(data as String) as Map<String, dynamic>;
      _messageController.add(parsed);
    } catch (_) {
      // Ignore non-JSON messages (e.g. pong responses).
    }
  }

  void _onError(Object error) {
    _setState(WsConnectionState.disconnected);
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _onDone() {
    _stopPing();
    _setState(WsConnectionState.disconnected);
    if (!_intentionalDisconnect) {
      _scheduleReconnect();
    }
  }

  void _startPing() {
    _stopPing();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (_state == WsConnectionState.connected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'method': 'ping'}));
        } catch (_) {
          // Connection may have closed between the check and the send.
        }
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) return;
    _reconnectTimer?.cancel();

    // Exponential backoff with jitter.
    final delayMs = reconnectBaseDelay.inMilliseconds *
        pow(2, _reconnectAttempts).toInt();
    final jitter = Random().nextInt(1000);
    final totalDelay = Duration(milliseconds: delayMs + jitter);

    _reconnectAttempts++;
    _reconnectTimer = Timer(totalDelay, () {
      if (!_intentionalDisconnect) {
        connect();
      }
    });
  }

  void _setState(WsConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose of all resources.
  ///
  /// After calling this, the transport cannot be reused.
  Future<void> dispose() async {
    await disconnect();
    await _messageController.close();
    await _stateController.close();
  }
}
