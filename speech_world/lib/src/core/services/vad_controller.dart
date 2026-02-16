/// VAD Controller (Voice Activity Detection)
///
/// Smart VAD Gating для Dialogue Mode.
/// Реализует:
/// - Pre-roll buffer 500ms для сохранения начала фразы
/// - Silero VAD (ML-based) с fallback на amplitude-based VAD
/// - Gate Open/Close с настраиваемыми таймаутами
/// - Barge-in detection
/// Silero VAD Parameters (configurable):
/// - Threshold: 0.0-1.0 (default 0.5)
/// - Min Speech Duration: 250ms (рекомендовано 200-300ms)
/// - Min Silence Duration: 800ms (рекомендовано 500-1000ms)
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'dialogue_websocket_service.dart';
import 'silero_vad_service.dart';

/// VAD State
enum VadState {
  /// Gate closed, only buffering pre-roll
  idle,

  /// Gate open, sending audio to network
  speechDetected,

  /// Speech ended, waiting for timeout to close gate
  speechEnding,
}

/// Audio chunk with metadata
class AudioChunk {
  final Uint8List data;
  final DateTime timestamp;
  final double rms;

  AudioChunk({required this.data, required this.timestamp, required this.rms});
}

/// VAD Controller Configuration
///
/// Параметры согласно Silero VAD рекомендациям:
/// - Threshold: 0.5 (default), 0.3 = чувствительный, 0.8 = строгий
/// - Min Speech Duration: 250ms (рекомендовано 200-300ms)
/// - Min Silence Duration: 800ms (рекомендовано 500-1000ms)
class VadConfig {
  /// Pre-roll buffer duration (500ms)
  static const Duration preRollDuration = Duration(milliseconds: 500);

  /// Timeout to close gate after speech ends (800ms)
  /// Рекомендовано: 500-1000ms
  static const Duration gateCloseTimeout = Duration(milliseconds: 800);

  /// Silero VAD threshold (0.0-1.0)
  /// Default: 0.5
  /// Lower (0.3) = more sensitive, may trigger on background noise
  /// Higher (0.8) = stricter, may cut quiet speech
  static const double vadThreshold = 0.5;

  /// Min speech duration to trigger gate open (milliseconds)
  /// Рекомендовано: 200-300ms
  static const int minSpeechDurationMs = 250;

  /// Min silence duration to close gate (milliseconds)
  /// Рекомендовано: 500-1000ms
  static const int minSilenceDurationMs = 800;

  /// Amplitude threshold for fallback VAD (-40dB = 0.01)
  static const double amplitudeThreshold = 0.01;

  /// RMS threshold for fallback VAD
  static const double rmsThreshold = 0.01;

  /// Sample rate (16kHz)
  static const int sampleRate = 16000;

  /// Bit depth (16-bit)
  static const int bitDepth = 16;

  /// Chunk duration for Silero VAD (30ms)
  static const Duration sileroChunkDuration = Duration(milliseconds: 30);

  /// Chunk duration for amplitude VAD (100ms)
  static const Duration amplitudeChunkDuration = Duration(milliseconds: 100);

  /// Bytes per sample (16-bit = 2 bytes)
  static const int bytesPerSample = 2;

  /// Pre-roll buffer size in bytes
  static int get preRollBufferSize =>
      (sampleRate * bytesPerSample * preRollDuration.inMilliseconds) ~/ 1000;

  /// Chunk size in bytes for amplitude VAD (100ms)
  static int get amplitudeChunkSize =>
      (sampleRate * bytesPerSample * amplitudeChunkDuration.inMilliseconds) ~/
      1000;

  /// Chunk size in bytes for Silero VAD (30ms)
  static int get sileroChunkSize =>
      (sampleRate * bytesPerSample * sileroChunkDuration.inMilliseconds) ~/
      1000;
}

/// Callback for VAD state changes
typedef VadStateCallback = void Function(VadState state);

/// Callback for audio data ready to send
typedef AudioDataCallback = void Function(Uint8List data);

/// Callback for barge-in detection
typedef BargeInCallback = void Function();

/// VAD Controller
///
/// Manages voice activity detection with smart gating:
/// 1. Accumulates audio in pre-roll buffer while gate is closed
/// 2. Detects speech using Silero VAD (ML-based) or amplitude-based fallback
/// 3. Opens gate and sends pre-roll buffer immediately
/// 4. Continues sending audio while speech is detected
/// 5. Closes gate after timeout when speech ends
///
/// Silero VAD Integration:
/// - Uses ML-based voice detection for better noise rejection
/// - Falls back to amplitude-based VAD if Silero model not loaded
/// - Configurable threshold, min speech/silence duration
class VadController {
  /// Current VAD state
  VadState _state = VadState.idle;

  /// Pre-roll buffer (circular buffer)
  final List<AudioChunk> _preRollBuffer = [];

  /// Current buffer size in bytes
  int _currentBufferSize = 0;

  /// Timer for gate close timeout
  Timer? _gateCloseTimer;

  /// Timer for barge-in debounce
  Timer? _bargeInDebounceTimer;

  /// Stream controller for VAD state
  final _stateController = StreamController<VadState>.broadcast();

  /// Stream controller for audio data
  final _audioController = StreamController<Uint8List>.broadcast();

  /// Stream controller for barge-in events
  final _bargeInController = StreamController<void>.broadcast();

  /// Callbacks
  VadStateCallback? onStateChanged;
  AudioDataCallback? onAudioData;
  BargeInCallback? onBargeIn;

  /// Whether VAD is active
  bool _isActive = false;

  /// Whether we're in AI playback mode (for barge-in)
  bool _isPlayingAiAudio = false;

  /// Current amplitude
  double _currentAmplitude = 0.0;

  /// Silero VAD service reference
  final SileroVadService _sileroVad = sileroVadService;

  /// Whether Silero VAD is loaded and available
  bool _sileroVadAvailable = false;

  /// Current speech probability from Silero VAD
  double _speechProbability = 0.0;

  /// Speech frames counter (for min speech duration)
  int _speechFrames = 0;

  /// Silence frames counter (for min silence duration)
  int _silenceFrames = 0;

  /// Get current state
  VadState get state => _state;

  /// Get state stream
  Stream<VadState> get stateStream => _stateController.stream;

  /// Get audio data stream
  Stream<Uint8List> get audioStream => _audioController.stream;

  /// Get barge-in stream
  Stream<void> get bargeInStream => _bargeInController.stream;

  /// Check if VAD is active
  bool get isActive => _isActive;

  /// Get current amplitude
  double get currentAmplitude => _currentAmplitude;

  /// Check if gate is open
  bool get isGateOpen => _state == VadState.speechDetected;

  /// Get current speech probability (from Silero VAD if available)
  double get speechProbability =>
      _sileroVadAvailable ? _speechProbability : _currentAmplitude;

  /// Check if Silero VAD is available
  bool get isSileroVadAvailable => _sileroVadAvailable;

  /// Initialize Silero VAD
  ///
  /// Call this once during app initialization to load the model.
  Future<bool> initializeSileroVad() async {
    debugPrint('[VADController] Initializing Silero VAD...');
    try {
      final loaded = await _sileroVad.initialize();
      _sileroVadAvailable = loaded;

      if (loaded) {
        debugPrint('[VADController] Silero VAD loaded successfully');
      } else {
        debugPrint(
          '[VADController] Silero VAD not available, using amplitude-based VAD',
        );
      }

      return loaded;
    } catch (e) {
      debugPrint('[VADController] Silero VAD initialization error: $e');
      _sileroVadAvailable = false;
      return false;
    }
  }

  /// Start VAD
  void start() {
    debugPrint('[VADController] Starting VAD...');
    _isActive = true;
    _state = VadState.idle;
    _preRollBuffer.clear();
    _currentBufferSize = 0;
    _gateCloseTimer?.cancel();
    _bargeInDebounceTimer?.cancel();
    _speechFrames = 0;
    _silenceFrames = 0;
    _speechProbability = 0.0;

    if (_sileroVadAvailable) {
      _sileroVad.reset();
      debugPrint('[VADController] VAD started with Silero VAD');
    } else {
      debugPrint('[VADController] VAD started with amplitude-based VAD');
    }

    debugPrint(
      '[VADController] VAD started, pre-roll buffer: ${VadConfig.preRollBufferSize} bytes',
    );
  }

  /// Stop VAD
  void stop() {
    debugPrint('[VADController] Stopping VAD...');
    _isActive = false;
    _state = VadState.idle;
    _preRollBuffer.clear();
    _currentBufferSize = 0;
    _gateCloseTimer?.cancel();
    _bargeInDebounceTimer?.cancel();
    debugPrint('[VADController] VAD stopped');
  }

  /// Process audio chunk
  ///
  /// This is the main entry point for audio data.
  /// Analyzes audio and manages gate state.
  /// Uses Silero VAD if available, otherwise falls back to amplitude-based VAD.
  void processAudioChunk(Uint8List data) {
    if (!_isActive) {
      debugPrint('[VADController] VAD not active, ignoring chunk');
      return;
    }

    // Calculate RMS/amplitude
    final rms = _calculateRms(data);
    _currentAmplitude = rms;

    // Use Silero VAD if available, otherwise use amplitude
    bool isSpeech = rms > VadConfig.rmsThreshold;

    if (_sileroVadAvailable) {
      // Try to get Silero VAD probability
      _sileroVad.processAudioChunk(data).then((probability) {
        if (probability >= 0) {
          _speechProbability = probability;
          final detected = _sileroVad.isSpeechDetected(probability);

          // Update frame counters for min duration checks
          _sileroVad.updateSpeechFrames(probability);

          debugPrint(
            '[VADController] Silero probability: ${probability.toStringAsFixed(3)}, isSpeech: $detected',
          );

          // Process with the detected speech state
          _processWithSpeechState(data, rms, detected);
        } else {
          // Fallback to amplitude
          _processWithSpeechState(data, rms, rms > VadConfig.rmsThreshold);
        }
      });
    } else {
      // Use amplitude-based VAD
      _processWithSpeechState(data, rms, isSpeech);
    }
  }

  /// Process chunk with determined speech state
  void _processWithSpeechState(Uint8List data, double rms, bool isSpeech) {
    final chunk = AudioChunk(data: data, timestamp: DateTime.now(), rms: rms);

    switch (_state) {
      case VadState.idle:
        _handleIdleStateWithSpeech(chunk, isSpeech);
        break;
      case VadState.speechDetected:
        _handleSpeechDetectedStateWithSpeech(chunk, isSpeech);
        break;
      case VadState.speechEnding:
        _handleSpeechEndingStateWithSpeech(chunk, isSpeech);
        break;
    }
  }

  /// Handle idle state with speech detection
  void _handleIdleStateWithSpeech(AudioChunk chunk, bool isSpeech) {
    // Add to pre-roll buffer
    _preRollBuffer.add(chunk);
    _currentBufferSize += chunk.data.length;

    // Trim buffer if too large
    while (_currentBufferSize > VadConfig.preRollBufferSize &&
        _preRollBuffer.isNotEmpty) {
      final removed = _preRollBuffer.removeAt(0);
      _currentBufferSize -= removed.data.length;
    }

    // Check for speech using Silero threshold or amplitude
    if (isSpeech) {
      _speechFrames++;
      final minSpeechFrames = VadConfig.minSpeechDurationMs ~/
          (_sileroVadAvailable ? SileroVadConfig.chunkDurationMs : VadConfig.amplitudeChunkDuration.inMilliseconds);
      
      // Only open gate if we have enough speech frames
      if (_speechFrames >= minSpeechFrames) {
        final detectionType = _sileroVadAvailable ? 'Silero' : 'Amplitude';
        debugPrint(
          '[$detectionType VADController] Speech detected! RMS: ${chunk.rms.toStringAsFixed(4)}, frames: $_speechFrames',
        );
        _openGate();
      }
    } else {
      _speechFrames = 0;
    }
  }

  /// Handle speech detected state with speech detection
  void _handleSpeechDetectedStateWithSpeech(AudioChunk chunk, bool isSpeech) {
    // Always send audio when gate is open
    _sendAudio(chunk.data);

    // Update frame counters
    if (isSpeech) {
      _speechFrames++;
      _silenceFrames = 0;

      // Check for barge-in if AI is playing
      if (_isPlayingAiAudio) {
        _triggerBargeIn();
      }
    } else {
      _silenceFrames++;
      _speechFrames = 0;
      // Speech might be ending, check timeout
      _checkSilenceTimeout();
    }
  }

  /// Handle speech ending state with speech detection
  void _handleSpeechEndingStateWithSpeech(AudioChunk chunk, bool isSpeech) {
    // Continue sending audio during timeout
    _sendAudio(chunk.data);

    // Check if speech resumed
    if (isSpeech) {
      debugPrint('[VADController] Speech resumed, canceling gate close');
      _gateCloseTimer?.cancel();
      _speechFrames++;
      _silenceFrames = 0;
      _state = VadState.speechDetected;
      _notifyStateChange();

      // Check for barge-in
      if (_isPlayingAiAudio) {
        _triggerBargeIn();
      }
    } else {
      _silenceFrames++;
      _checkSilenceTimeout();
    }
    // If timeout expires, gate will close automatically
  }

  /// Check if silence timeout should close the gate
  void _checkSilenceTimeout() {
    final minSilenceFrames =
        VadConfig.minSilenceDurationMs ~/
        (_sileroVadAvailable
            ? SileroVadConfig.chunkDurationMs
            : VadConfig.amplitudeChunkDuration.inMilliseconds);

    if (_silenceFrames >= minSilenceFrames) {
      debugPrint('[VADController] Silence timeout reached, closing gate');
      _closeGate();
    } else if (!(_gateCloseTimer?.isActive ?? false)) {
      _startGateCloseTimeout();
    }
  }

  /// Open gate and send pre-roll buffer
  void _openGate() {
    debugPrint('[VADController] Opening gate, sending pre-roll buffer...');
    _state = VadState.speechDetected;
    _notifyStateChange();

    // Send all accumulated pre-roll audio
    final totalBytes = _preRollBuffer.fold<int>(
      0,
      (sum, c) => sum + c.data.length,
    );
    debugPrint(
      '[VADController] Sending ${_preRollBuffer.length} chunks, $totalBytes bytes',
    );

    for (final chunk in _preRollBuffer) {
      _sendAudio(chunk.data);
    }

    // Clear pre-roll buffer
    _preRollBuffer.clear();
    _currentBufferSize = 0;

    debugPrint('[VADController] Gate opened, pre-roll sent');
  }

  /// Start gate close timeout
  void _startGateCloseTimeout() {
    if (_gateCloseTimer?.isActive ?? false) return;

    debugPrint('[VADController] Starting gate close timeout...');
    _state = VadState.speechEnding;
    _notifyStateChange();

    _gateCloseTimer = Timer(VadConfig.gateCloseTimeout, () {
      debugPrint('[VADController] Gate close timeout expired, closing gate');
      _closeGate();
    });
  }

  /// Close gate
  void _closeGate() {
    debugPrint('[VADController] Closing gate');
    _state = VadState.idle;
    _preRollBuffer.clear();
    _currentBufferSize = 0;
    _gateCloseTimer?.cancel();
    _notifyStateChange();

    // Signal to backend that user finished speaking
    debugPrint('[VADController] Sending turn_complete signal');
    dialogueWebSocketService.sendTurnComplete();
  }

  /// Send audio data
  void _sendAudio(Uint8List data) {
    _audioController.add(data);
    onAudioData?.call(data);
  }

  /// Trigger barge-in
  void _triggerBargeIn() {
    // Debounce barge-in events
    if (_bargeInDebounceTimer?.isActive ?? false) return;

    debugPrint('[VADController] BARGE-IN detected!');
    _bargeInController.add(null);
    onBargeIn?.call();

    // Debounce for 100ms to avoid spam
    _bargeInDebounceTimer = Timer(const Duration(milliseconds: 100), () {});
  }

  /// Notify state change
  void _notifyStateChange() {
    debugPrint('[VADController] State: $_state');
    _stateController.add(_state);
    onStateChanged?.call(_state);
  }

  /// Calculate RMS (Root Mean Square) of audio data
  ///
  /// Returns normalized value 0.0 to 1.0
  double _calculateRms(Uint8List data) {
    if (data.isEmpty) return 0.0;

    // Convert bytes to 16-bit samples
    final sampleCount = data.length ~/ 2;
    if (sampleCount == 0) return 0.0;

    double sumSquares = 0.0;

    for (int i = 0; i < data.length - 1; i += 2) {
      // Convert two bytes to signed 16-bit integer
      final sample = data.buffer.asByteData().getInt16(i, Endian.little);
      // Normalize to -1.0 to 1.0
      final normalized = sample / 32768.0;
      sumSquares += normalized * normalized;
    }

    final rms = sqrt(sumSquares / sampleCount);

    // Debug logging for high amplitude
    if (rms > VadConfig.rmsThreshold) {
      debugPrint(
        '[VADController] RMS: ${rms.toStringAsFixed(4)} (above threshold)',
      );
    }

    return rms;
  }

  /// Set AI playback state (for barge-in detection)
  void setAiPlaybackState(bool isPlaying) {
    if (_isPlayingAiAudio != isPlaying) {
      debugPrint('[VADController] AI playback state: $isPlaying');
      _isPlayingAiAudio = isPlaying;
    }
  }

  /// Force gate close (e.g., when session ends)
  void forceCloseGate() {
    debugPrint('[VADController] Force closing gate');
    _gateCloseTimer?.cancel();
    _closeGate();
  }

  /// Dispose resources
  void dispose() {
    debugPrint('[VADController] Disposing...');
    stop();
    _stateController.close();
    _audioController.close();
    _bargeInController.close();
    debugPrint('[VADController] Disposed');
  }
}

/// Singleton instance
final vadController = VadController();
