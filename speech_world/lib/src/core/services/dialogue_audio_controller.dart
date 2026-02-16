/// Dialogue Audio Controller
/// 
/// Coordinates audio recording and playback for Dialogue Mode.
/// Manages the audio pipeline: Record → VAD → WebSocket → Playback
/// Includes Smart VAD Gating, AEC/NS, and Barge-in detection.
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_recorder_service.dart';
import 'audio_player_service.dart';
import 'audio_session_service.dart';
import 'dialogue_websocket_service.dart';
import 'vad_controller.dart';

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
/// 3. Start VAD-controlled recording
/// 4. Stream audio to WebSocket (only when speech detected)
/// 5. Play responses from WebSocket
/// 6. Handle barge-in (interrupt AI when user speaks)
class DialogueAudioController extends ChangeNotifier {
  final AudioRecorderService _recorder;
  final AudioPlayerService _player;
  final AudioSessionService _session;
  final DialogueWebSocketService _webSocket;
  final VadController _vad;

  AudioControllerState _state = AudioControllerState.idle;
  String? _errorMessage;
  String? _sessionId;
  
  StreamSubscription? _interruptionSubscription;
  StreamSubscription? _vadStateSubscription;
  StreamSubscription? _vadAudioSubscription;
  StreamSubscription? _bargeInSubscription;
  Timer? _amplitudeTimer;
  double _currentAmplitude = 0.0;
  bool _isWaitingForSessionStart = false;

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
  
  /// Current VAD state
  VadState get vadState => _vad.state;
  
  /// Check if VAD gate is open
  bool get isVadGateOpen => _vad.isGateOpen;

  /// Constructor
  DialogueAudioController({
    AudioRecorderService? recorder,
    AudioPlayerService? player,
    AudioSessionService? session,
    DialogueWebSocketService? webSocket,
    VadController? vad,
  })  : _recorder = recorder ?? AudioRecorderService(),
        _player = player ?? AudioPlayerService(),
        _session = session ?? AudioSessionService(),
        _webSocket = webSocket ?? DialogueWebSocketService(),
        _vad = vad ?? VadController() {
    // Setup WebSocket callbacks
    _webSocket.onMessageReceived = _handleWebSocketMessage;
    _webSocket.onStateChanged = _handleWebSocketStateChange;
    _webSocket.onError = _handleWebSocketError;
    
    // Setup VAD callbacks
    _setupVadCallbacks();
  }

  /// Setup VAD callbacks
  void _setupVadCallbacks() {
    _vad.onStateChanged = (state) {
      debugPrint('[DialogueAudioController] VAD state: $state');
      notifyListeners();
    };
    
    _vad.onAudioData = (data) {
      // Send audio to WebSocket only when VAD gate is open
      if (_webSocket.isConnected && _state != AudioControllerState.error) {
        _webSocket.sendAudio(data);
      }
    };
    
    _vad.onBargeIn = () {
      debugPrint('[DialogueAudioController] Barge-in detected!');
      _handleBargeIn();
    };
  }

  /// Initialize the controller
  /// 
  /// Sets up audio session and prepares recording/playback.
  Future<bool> initialize() async {
    debugPrint('[DialogueAudioController] Initializing...');
    _setState(AudioControllerState.initializing);

    try {
      // Check and request microphone permission
      debugPrint('[DialogueAudioController] Checking microphone permission...');
      final micStatus = await Permission.microphone.status;
      debugPrint('[DialogueAudioController] Microphone permission status: $micStatus');
      
      if (!micStatus.isGranted) {
        debugPrint('[DialogueAudioController] Requesting microphone permission...');
        final result = await Permission.microphone.request();
        debugPrint('[DialogueAudioController] Microphone permission result: $result');
        
        if (!result.isGranted) {
          throw Exception('Microphone permission denied');
        }
      }

      // Configure audio session for dialogue with AEC/NS
      debugPrint('[DialogueAudioController] Configuring audio session...');
      final sessionConfigured = await _session.configureForDialogue();
      if (!sessionConfigured) {
        throw Exception('Failed to configure audio session');
      }
      debugPrint('[DialogueAudioController] Audio session configured');

      // Activate audio session
      debugPrint('[DialogueAudioController] Activating audio session...');
      final sessionActivated = await _session.activate();
      if (!sessionActivated) {
        throw Exception('Failed to activate audio session');
      }
      debugPrint('[DialogueAudioController] Audio session activated');

      // Initialize recorder
      debugPrint('[DialogueAudioController] Initializing recorder...');
      final recorderInitialized = await _recorder.initialize();
      if (!recorderInitialized) {
        throw Exception('Failed to initialize audio recorder');
      }
      debugPrint('[DialogueAudioController] Recorder initialized');

      // Initialize player
      debugPrint('[DialogueAudioController] Initializing player...');
      await _player.initialize();
      debugPrint('[DialogueAudioController] Player initialized');

      // Listen to audio interruptions
      _interruptionSubscription = _session.interruptionEvents.listen(_handleInterruption);

      _setState(AudioControllerState.ready);
      debugPrint('[DialogueAudioController] Initialization complete');
      return true;
    } catch (e) {
      debugPrint('[DialogueAudioController] Initialization failed: $e');
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
  /// Connects to WebSocket and waits for session to start before recording.
  Future<bool> startSession({
    required String l1Language,
    required String l2Language,
  }) async {
    debugPrint('[DialogueAudioController] Starting session: $l1Language ↔ $l2Language');
    try {
      // Connect if not already connected
      if (!isConnected) {
        debugPrint('[DialogueAudioController] Not connected, connecting first...');
        final connected = await connect();
        if (!connected) return false;
      }

      _setState(AudioControllerState.connecting);
      _isWaitingForSessionStart = true;

      // Wait for session to start
      debugPrint('[DialogueAudioController] Waiting for session to start...');
      final sessionStarted = await _waitForSessionStart(
        l1Language: l1Language,
        l2Language: l2Language,
      );

      if (!sessionStarted) {
        throw Exception('Session did not start within timeout');
      }

      debugPrint('[DialogueAudioController] Session started successfully');
      return true;
    } catch (e) {
      debugPrint('[DialogueAudioController] Failed to start session: $e');
      _setError('Failed to start session: $e');
      return false;
    }
  }

  /// Wait for session to start
  Future<bool> _waitForSessionStart({
    required String l1Language,
    required String l2Language,
  }) async {
    final completer = Completer<bool>();
    final timeout = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        debugPrint('[DialogueAudioController] Session start timeout');
        completer.complete(false);
      }
    });

    // Store original callback
    final originalCallback = _webSocket.onMessageReceived;

    // Setup listener for session started message
    void onMessageReceived(ServerMessage message) {
      debugPrint('[DialogueAudioController] Received message: ${message.type}');
      
      if (message.type == ServerMessageType.started) {
        if (!completer.isCompleted) {
          timeout.cancel();
          _sessionId = message.sessionId;
          _setState(AudioControllerState.connected);
          _isWaitingForSessionStart = false;
          debugPrint('[DialogueAudioController] Session confirmed, starting recording...');
          
          // Restore original callback
          _webSocket.onMessageReceived = originalCallback;
          
          // Now start recording with VAD
          _startRecordingWithVad();
          completer.complete(true);
        }
      } else if (message.type == ServerMessageType.error) {
        if (!completer.isCompleted) {
          timeout.cancel();
          _isWaitingForSessionStart = false;
          _setError(message.message ?? 'Session start failed');
          completer.complete(false);
        }
      }
      
      // Still call original callback for other messages
      originalCallback?.call(message);
    }

    _webSocket.onMessageReceived = onMessageReceived;
    _webSocket.startSession(
      l1Language: l1Language,
      l2Language: l2Language,
    );

    return await completer.future;
  }

  /// Start recording with VAD
  Future<void> _startRecordingWithVad() async {
    debugPrint('[DialogueAudioController] Starting recording with VAD...');
    try {
      if (!_isSessionActive()) {
        debugPrint('[DialogueAudioController] Cannot start recording - session not active');
        return;
      }
      
      // Check permission again before recording
      final micStatus = await Permission.microphone.status;
      debugPrint('[DialogueAudioController] Microphone status before recording: $micStatus');
      
      if (!micStatus.isGranted) {
        debugPrint('[DialogueAudioController] Microphone permission not granted');
        _setError('Microphone permission denied');
        return;
      }
      
      // Start VAD first
      debugPrint('[DialogueAudioController] Starting VAD...');
      _vad.start();
      
      // Start recording - audio goes to VAD
      await _recorder.startRecording(
        onAudioData: (data) {
          // Send to VAD instead of directly to WebSocket
          _vad.processAudioChunk(data);
        },
        onStateChanged: (isRecording) {
          debugPrint('[DialogueAudioController] Recording state: $isRecording');
          if (isRecording) {
            _setState(AudioControllerState.recording);
            _startAmplitudeMonitoring();
          }
        },
      );
      debugPrint('[DialogueAudioController] Recording with VAD started');
    } catch (e, stackTrace) {
      debugPrint('[DialogueAudioController] Failed to start recording: $e');
      debugPrint('[DialogueAudioController] Stack trace: $stackTrace');
      _setError('Failed to start recording: $e');
    }
  }

  /// Handle barge-in (user speaks while AI is playing)
  void _handleBargeIn() {
    debugPrint('[DialogueAudioController] Handling barge-in...');
    
    // Stop playback immediately
    if (_player.isPlaying) {
      debugPrint('[DialogueAudioController] Stopping AI playback due to barge-in');
      _player.stop();
    }
    
    // Notify that barge-in occurred
    notifyListeners();
  }

  /// Public method to start recording (called from UI)
  /// 
  /// Note: With VAD, recording starts automatically when session is ready.
  /// This method exists for UI compatibility with tap-to-speak interface.
  void startRecording() {
    debugPrint('[DialogueAudioController] startRecording() called');
    if (!_isSessionActive()) {
      debugPrint('[DialogueAudioController] Cannot start recording - not connected');
      _setError('Not connected to server');
    } else {
      debugPrint('[DialogueAudioController] Recording starts automatically with VAD when speech detected');
    }
  }

  /// Stop recording
  Future<void> stopRecording() async {
    debugPrint('[DialogueAudioController] Stopping recording...');
    try {
      // Stop VAD first
      _vad.stop();
      
      await _recorder.stopRecording();
      _stopAmplitudeMonitoring();
      _currentAmplitude = 0.0;
      
      if (isConnected) {
        _setState(AudioControllerState.connected);
      } else {
        _setState(AudioControllerState.ready);
      }
      debugPrint('[DialogueAudioController] Recording stopped');
    } catch (e) {
      debugPrint('[DialogueAudioController] Failed to stop recording: $e');
      _setError('Failed to stop recording: $e');
    }
  }

  /// Stop the dialogue session
  Future<void> stopSession() async {
    debugPrint('[DialogueAudioController] Stopping session...');
    try {
      // Stop recording first
      await stopRecording();
      
      // Stop WebSocket session
      _webSocket.stopSession();
      
      _sessionId = null;
      _setState(AudioControllerState.ready);
      debugPrint('[DialogueAudioController] Session stopped');
    } catch (e) {
      debugPrint('[DialogueAudioController] Failed to stop session: $e');
      _setError('Failed to stop session: $e');
    }
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    debugPrint('[DialogueAudioController] Disconnecting...');
    await stopRecording();
    await _webSocket.disconnect();
    _sessionId = null;
    _setState(AudioControllerState.disconnected);
    debugPrint('[DialogueAudioController] Disconnected');
  }

  /// Play audio response
  /// 
  /// Plays PCM audio data received from the WebSocket.
  Future<void> playResponse(Uint8List pcmData) async {
    try {
      debugPrint('[DialogueAudioController] Playing response: ${pcmData.length} bytes');
      
      // Notify VAD that AI is about to play
      _vad.setAiPlaybackState(true);
      
      _setState(AudioControllerState.playing);
      
      await _player.playPcm(
        pcmData: pcmData,
        onStateChanged: (state) {
          debugPrint('[DialogueAudioController] Playback state: $state');
          if (state == PlaybackState.completed ||
              state == PlaybackState.idle ||
              state == PlaybackState.error) {
            // Notify VAD that AI finished playing
            _vad.setAiPlaybackState(false);
            
            if (isConnected && _recorder.isRecording) {
              _setState(AudioControllerState.recording);
            } else if (isConnected) {
              _setState(AudioControllerState.connected);
            } else {
              _setState(AudioControllerState.ready);
            }
          }
        },
        onError: (error) {
          _vad.setAiPlaybackState(false);
          _setError('Playback error: $error');
        },
      );
    } catch (e) {
      debugPrint('[DialogueAudioController] Failed to play response: $e');
      _vad.setAiPlaybackState(false);
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
    debugPrint('[DialogueAudioController] WebSocket message: ${message.type}');
    
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
        debugPrint('[DialogueAudioController] Received audio: ${message.data?.length ?? 0} chars');
        if (message.data != null) {
          final audioData = base64Decode(message.data!);
          debugPrint('[DialogueAudioController] Decoded audio: ${audioData.length} bytes');
          playResponse(audioData);
        }
        break;
        
      case ServerMessageType.text:
        // Text message received (transcription or translation)
        debugPrint('[DialogueAudioController] Text message: ${message.message}');
        break;
        
      case ServerMessageType.error:
        // Error from server
        debugPrint('[DialogueAudioController] Server error: ${message.message}');
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
    debugPrint('[DialogueAudioController] WebSocket state: $state');
    switch (state) {
      case WebSocketState.connected:
        if (_state != AudioControllerState.recording && !_isWaitingForSessionStart) {
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
    debugPrint('[DialogueAudioController] WebSocket error: $error');
    _setError('WebSocket error: $error');
  }

  /// Handle audio interruptions (phone calls, etc.)
  void _handleInterruption(AudioInterruptionEvent event) {
    debugPrint('[DialogueAudioController] Audio interruption: ${event.begin}');
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
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 50), (_) async {
      // Use VAD amplitude if available, otherwise fallback to recorder
      if (_vad.isActive) {
        _currentAmplitude = _vad.currentAmplitude;
        notifyListeners();
      } else {
        final amplitude = await _recorder.getAmplitude();
        if (amplitude != null) {
          _currentAmplitude = amplitude;
          notifyListeners();
        }
      }
    });
  }

  /// Stop amplitude monitoring
  void _stopAmplitudeMonitoring() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    _currentAmplitude = 0.0;
  }

  /// Check if session is active and connected
  bool _isSessionActive() {
    return _webSocket.isConnected && _state != AudioControllerState.error && _state != AudioControllerState.disconnected;
  }

  /// Dispose the controller
  @override
  void dispose() {
    debugPrint('[DialogueAudioController] Disposing...');
    _stopAmplitudeMonitoring();
    _interruptionSubscription?.cancel();
    _vadStateSubscription?.cancel();
    _vadAudioSubscription?.cancel();
    _bargeInSubscription?.cancel();
    _vad.dispose();
    _webSocket.dispose();
    _recorder.dispose();
    _player.dispose();
    _session.dispose();
    super.dispose();
    debugPrint('[DialogueAudioController] Disposed');
  }

  /// Set state and notify listeners
  void _setState(AudioControllerState newState) {
    if (_state != newState) {
      debugPrint('[DialogueAudioController] State: $_state → $newState');
      _state = newState;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String message) {
    debugPrint('[DialogueAudioController] Error: $message');
    _state = AudioControllerState.error;
    _errorMessage = message;
    notifyListeners();
  }
}
