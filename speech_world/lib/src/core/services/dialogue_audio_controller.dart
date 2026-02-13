/// Dialogue Audio Controller
/// 
/// Coordinates audio recording and playback for Dialogue Mode.
/// Manages the audio pipeline: Record → WebSocket → Playback
/// Includes VAD (Voice Activity Detection) and AEC/NS via AudioSession.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'audio_recorder_service.dart';
import 'audio_player_service.dart';
import 'audio_session_service.dart';
import 'dialogue_websocket_service.dart';

/// Audio controller state
enum AudioControllerState {
  idle,
  initializing,
  ready,
  connecting,
  connected,
  recording,
  playing,
  error,
  disconnected,
}

/// Dialogue Audio Controller
/// 
/// Manages the complete audio lifecycle for Dialogue Mode:
/// 1. Configure audio session (AEC/NS)
/// 2. Connect to WebSocket
/// 3. Start recording from microphone
/// 4. Stream audio to WebSocket
/// 5. Play responses from WebSocket
class DialogueAudioController extends ChangeNotifier {
  final AudioRecorderService _recorder;
  final AudioPlayerService _player;
  final AudioSessionService _session;
  final DialogueWebSocketService _webSocket;

  AudioControllerState _state = AudioControllerState.idle;
  String? _errorMessage;
  String? _sessionId;
  
  StreamSubscription? _interruptionSubscription;
  Timer? _amplitudeTimer;
  double _currentAmplitude = 0.0;

  /// Current state
  AudioControllerState get state => _state;
  
  /// Error message if state is error
  String? get errorMessage => _errorMessage;
  
  /// Current session ID
  String? get sessionId => _sessionId;
  
  /// Check if recording
  bool get isRecording => _state == AudioControllerState.recording;
  
  /// Check if playing
  bool get isPlaying => _player.state == PlaybackState.playing;
  
  /// Check if connected to WebSocket
  bool get isConnected => _webSocket.isConnected;
  
  /// Check if ready
  bool get isReady => _state == AudioControllerState.ready;
  
  /// Current recording amplitude (0.0 to 1.0)
  double get currentAmplitude => _currentAmplitude;

  /// Constructor
  DialogueAudioController({
    AudioRecorderService? recorder,
    AudioPlayerService? player,
    AudioSessionService? session,
    DialogueWebSocketService? webSocket,
  })  : _recorder = recorder ?? AudioRecorderService(),
        _player = player ?? AudioPlayerService(),
        _session = session ?? AudioSessionService(),
        _webSocket = webSocket ?? DialogueWebSocketService() {
    // Setup WebSocket callbacks
    _webSocket.onMessageReceived = _handleWebSocketMessage;
    _webSocket.onStateChanged = _handleWebSocketStateChange;
    _webSocket.onError = _handleWebSocketError;
  }

  /// Initialize the controller
  /// 
  /// Sets up audio session and prepares recording/playback.
  Future<bool> initialize() async {
    _setState(AudioControllerState.initializing);

    try {
      // Configure audio session for dialogue with AEC/NS
      await _session.configureForDialogue();
      await _session.activate();

      // Initialize recorder
      final recorderInitialized = await _recorder.initialize();
      if (!recorderInitialized) {
        throw Exception('Failed to initialize audio recorder');
      }

      // Initialize player
      await _player.initialize();

      // Listen to audio interruptions
      _interruptionSubscription = _session.interruptionEvents.listen(_handleInterruption);

      _setState(AudioControllerState.ready);
      return true;
    } catch (e) {
      _setError('Failed to initialize audio: $e');
      return false;
    }
  }

  /// Connect to WebSocket server
  /// 
  /// Establishes connection to backend for dialogue session.
  Future<bool> connect() async {
    if (_state == AudioControllerState.connecting ||
        _state == AudioControllerState.connected) {
      return true;
    }

    _setState(AudioControllerState.connecting);
    debugPrint('[DialogueAudioController] Connecting to WebSocket...');

    try {
      final connected = await _webSocket.connect();
      if (!connected) {
        throw Exception(_webSocket.errorMessage ?? 'Failed to connect');
      }
      debugPrint('[DialogueAudioController] WebSocket connected successfully');
      return true;
    } catch (e) {
      debugPrint('[DialogueAudioController] Failed to connect: $e');
      _setError('Failed to connect: $e');
      return false;
    }
  }

  /// Start a dialogue session
  /// 
  /// Connects to WebSocket and starts recording.
  Future<bool> startSession({
    required String l1Language,
    required String l2Language,
  }) async {
    try {
      // Connect if not already connected
      if (!isConnected) {
        final connected = await connect();
        if (!connected) return false;
      }

      // Start WebSocket session
      _webSocket.startSession(
        l1Language: l1Language,
        l2Language: l2Language,
      );

      _sessionId = _webSocket.sessionId;
      _setState(AudioControllerState.connected);

      // Start recording
      await startRecording();

      return true;
    } catch (e) {
      _setError('Failed to start session: $e');
      return false;
    }
  }

  /// Start recording
  /// 
  /// Begins capturing audio from microphone and streams it to WebSocket.
  Future<void> startRecording() async {
    if (!isConnected) {
      throw Exception('Not connected to WebSocket');
    }

    try {
      await _recorder.startRecording(
        onAudioData: (data) {
          // Send audio data to WebSocket
          _webSocket.sendAudio(data);
        },
        onStateChanged: (isRecording) {
          if (isRecording) {
            _setState(AudioControllerState.recording);
            _startAmplitudeMonitoring();
          }
        },
      );
    } catch (e) {
      _setError('Failed to start recording: $e');
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    try {
      await _recorder.stopRecording();
      _stopAmplitudeMonitoring();
      _currentAmplitude = 0.0;
      
      if (isConnected) {
        _setState(AudioControllerState.connected);
      } else {
        _setState(AudioControllerState.ready);
      }
    } catch (e) {
      _setError('Failed to stop recording: $e');
    }
  }

  /// Stop the dialogue session
  Future<void> stopSession() async {
    try {
      // Stop recording first
      await stopRecording();
      
      // Stop WebSocket session
      _webSocket.stopSession();
      
      _sessionId = null;
      _setState(AudioControllerState.ready);
    } catch (e) {
      _setError('Failed to stop session: $e');
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    await stopRecording();
    await _webSocket.disconnect();
    _sessionId = null;
    _setState(AudioControllerState.disconnected);
  }

  /// Play audio response
  /// 
  /// Plays PCM audio data received from the WebSocket.
  Future<void> playResponse(Uint8List pcmData) async {
    try {
      // Pause recording while playing to prevent echo
      final wasRecording = isRecording;
      if (wasRecording) {
        await _recorder.pauseRecording();
      }

      _setState(AudioControllerState.playing);
      
      await _player.playPcm(
        pcmData: pcmData,
        onStateChanged: (state) {
          if (state == PlaybackState.completed ||
              state == PlaybackState.idle ||
              state == PlaybackState.error) {
            // Resume recording if it was active
            if (wasRecording && isConnected) {
              _recorder.resumeRecording();
              _setState(AudioControllerState.recording);
            } else if (isConnected) {
              _setState(AudioControllerState.connected);
            } else {
              _setState(AudioControllerState.ready);
            }
          }
        },
        onError: (error) {
          _setError('Playback error: $error');
        },
      );
    } catch (e) {
      _setError('Failed to play response: $e');
    }
  }

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// Get current volume
  double get volume => _player.volume;

  /// Handle WebSocket messages
  void _handleWebSocketMessage(ServerMessage message) {
    switch (message.type) {
      case ServerMessageType.connected:
        // Connection established, languages received
        break;
        
      case ServerMessageType.started:
        // Session started
        _sessionId = message.sessionId;
        break;
        
      case ServerMessageType.audio:
        // Audio response received
        if (message.data != null) {
          final audioData = base64Decode(message.data!);
          playResponse(audioData);
        }
        break;
        
      case ServerMessageType.text:
        // Text message received (transcription or translation)
        // Can be used for UI display
        break;
        
      case ServerMessageType.error:
        // Error from server
        _setError(message.message ?? 'Unknown server error');
        break;
        
      case ServerMessageType.stopped:
        // Session stopped
        _sessionId = null;
        break;
        
      default:
        break;
    }
  }

  /// Handle WebSocket state changes
  void _handleWebSocketStateChange(WebSocketState state) {
    switch (state) {
      case WebSocketState.connected:
        if (_state != AudioControllerState.recording) {
          _setState(AudioControllerState.connected);
        }
        break;
      case WebSocketState.disconnected:
        _setState(AudioControllerState.disconnected);
        break;
      case WebSocketState.error:
        _setState(AudioControllerState.error);
        break;
      default:
        break;
    }
  }

  /// Handle WebSocket errors
  void _handleWebSocketError(String error) {
    _setError('WebSocket error: $error');
  }

  /// Handle audio interruptions (phone calls, etc.)
  void _handleInterruption(AudioInterruptionEvent event) {
    if (event.begin) {
      // Interruption began (e.g., phone call)
      // Pause recording and playback
      if (_recorder.isRecording) {
        _recorder.pauseRecording();
      }
      if (_player.isPlaying) {
        _player.pause();
      }
    } else {
      // Interruption ended
      // Resume if needed
      if (_state == AudioControllerState.recording) {
        _recorder.resumeRecording();
      }
    }
  }

  /// Start amplitude monitoring for visualization
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      final amplitude = await _recorder.getAmplitude();
      if (amplitude != null) {
        _currentAmplitude = amplitude;
        notifyListeners();
      }
    });
  }

  /// Stop amplitude monitoring
  void _stopAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _currentAmplitude = 0.0;
  }

  /// Dispose the controller
  @override
  void dispose() {
    _stopAmplitudeMonitoring();
    _interruptionSubscription?.cancel();
    _webSocket.dispose();
    _recorder.dispose();
    _player.dispose();
    _session.dispose();
    super.dispose();
  }

  /// Set state and notify listeners
  void _setState(AudioControllerState newState) {
    if (_state != newState) {
      _state = newState;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String message) {
    _state = AudioControllerState.error;
    _errorMessage = message;
    notifyListeners();
  }
}
