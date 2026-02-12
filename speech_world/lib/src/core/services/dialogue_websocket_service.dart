/// Dialogue WebSocket Service
/// 
/// Manages WebSocket connection to backend for Dialogue Mode.
/// Handles authentication, message routing, and reconnection logic.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

/// WebSocket connection state
enum WebSocketState {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}

/// Server message types
enum ServerMessageType {
  connected,
  started,
  audio,
  text,
  error,
  stopped,
  unknown,
}

/// Server message from backend
class ServerMessage {
  final ServerMessageType type;
  final String? sessionId;
  final String? data; // base64 encoded audio or text
  final String? message;
  final List<dynamic>? supportedLanguages;

  ServerMessage({
    required this.type,
    this.sessionId,
    this.data,
    this.message,
    this.supportedLanguages,
  });

  factory ServerMessage.fromJson(Map<String, dynamic> json) {
    return ServerMessage(
      type: _parseMessageType(json['type'] as String?),
      sessionId: json['sessionId'] as String?,
      data: json['data'] as String?,
      message: json['message'] as String?,
      supportedLanguages: json['supportedLanguages'] as List<dynamic>?,
    );
  }

  static ServerMessageType _parseMessageType(String? type) {
    switch (type) {
      case 'connected':
        return ServerMessageType.connected;
      case 'started':
        return ServerMessageType.started;
      case 'audio':
        return ServerMessageType.audio;
      case 'text':
        return ServerMessageType.text;
      case 'error':
        return ServerMessageType.error;
      case 'stopped':
        return ServerMessageType.stopped;
      default:
        return ServerMessageType.unknown;
    }
  }
}

/// Callbacks for WebSocket events
typedef OnMessageReceived = void Function(ServerMessage message);
typedef OnStateChanged = void Function(WebSocketState state);
typedef OnError = void Function(String error);

/// Dialogue WebSocket Service
/// 
/// Manages real-time communication with backend for Dialogue Mode.
class DialogueWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  
  WebSocketState _state = WebSocketState.disconnected;
  String? _sessionId;
  String? _errorMessage;
  
  // Reconnection settings
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;
  
  // Callbacks
  OnMessageReceived? onMessageReceived;
  OnStateChanged? onStateChanged;
  OnError? onError;

  /// Current connection state
  WebSocketState get state => _state;
  
  /// Current session ID
  String? get sessionId => _sessionId;
  
  /// Error message if state is error
  String? get errorMessage => _errorMessage;
  
  /// Check if connected
  bool get isConnected => _state == WebSocketState.connected;
  
  /// Check if connecting
  bool get isConnecting => _state == WebSocketState.connecting;

  /// Connect to WebSocket server
  /// 
  /// Authenticates with Firebase ID token and establishes connection.
  Future<bool> connect() async {
    if (_state == WebSocketState.connected || 
        _state == WebSocketState.connecting) {
      return true;
    }

    _setState(WebSocketState.connecting);
    _errorMessage = null;

    try {
      // Get Firebase ID token for authentication
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final token = await user.getIdToken();
      
      // Build WebSocket URL with auth token
      final wsUrl = '${ApiConfig.wsBaseUrl}/dialogue?token=$token';
      
      // Connect to WebSocket
      _channel = IOWebSocketChannel.connect(
        wsUrl,
        connectTimeout: const Duration(seconds: 10),
      );

      // Listen to messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;
      
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  /// Start a dialogue session
  /// 
  /// Sends start message to backend with language pair.
  void startSession({
    required String l1Language,
    required String l2Language,
  }) {
    if (!isConnected) {
      throw Exception('WebSocket not connected. Call connect() first.');
    }

    _sessionId = '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';

    final message = {
      'type': 'start',
      'sessionId': _sessionId,
      'l1Language': l1Language,
      'l2Language': l2Language,
    };

    _sendMessage(message);
  }

  /// Send audio data to backend
  /// 
  /// [audioData] - Raw PCM audio bytes
  void sendAudio(Uint8List audioData) {
    if (!isConnected || _sessionId == null) return;

    final base64Data = base64Encode(audioData);
    
    final message = {
      'type': 'audio',
      'sessionId': _sessionId,
      'data': base64Data,
    };

    _sendMessage(message);
  }

  /// Send text message to backend
  void sendText(String text) {
    if (!isConnected || _sessionId == null) return;

    final message = {
      'type': 'text',
      'sessionId': _sessionId,
      'data': text,
    };

    _sendMessage(message);
  }

  /// Stop the dialogue session
  void stopSession() {
    if (!isConnected || _sessionId == null) return;

    final message = {
      'type': 'stop',
      'sessionId': _sessionId,
    };

    _sendMessage(message);
    _sessionId = null;
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = _maxReconnectAttempts; // Prevent reconnection
    
    await _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    
    _sessionId = null;
    _setState(WebSocketState.disconnected);
  }

  /// Handle incoming message
  void _handleMessage(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;
      final message = ServerMessage.fromJson(json);
      
      // Handle errors from server
      if (message.type == ServerMessageType.error) {
        _errorMessage = message.message;
      }
      
      onMessageReceived?.call(message);
    } catch (e) {
      onError?.call('Failed to parse message: $e');
    }
  }

  /// Handle connection error
  void _handleError(dynamic error) {
    _errorMessage = error.toString();
    _setState(WebSocketState.error);
    onError?.call(_errorMessage!);
    
    // Attempt reconnection if appropriate
    _attemptReconnection();
  }

  /// Handle disconnection
  void _handleDisconnect() {
    if (_state != WebSocketState.disconnected) {
      _setState(WebSocketState.disconnected);
      _attemptReconnection();
    }
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    _setState(WebSocketState.reconnecting);

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay = _initialReconnectDelay * (1 << (_reconnectAttempts - 1));
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  /// Send message to server
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) return;
    
    try {
      final json = jsonEncode(message);
      _channel!.sink.add(json);
    } catch (e) {
      onError?.call('Failed to send message: $e');
    }
  }

  /// Update state and notify listeners
  void _setState(WebSocketState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(newState);
    }
  }

  /// Generate random string for session ID
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (index) {
      return chars[(random + index) % chars.length];
    }).join();
  }

  /// Dispose the service
  void dispose() {
    disconnect();
  }
}

/// Singleton instance
final dialogueWebSocketService = DialogueWebSocketService();
