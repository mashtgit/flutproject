/// Echo Audio Controller
/// 
/// Test mode controller that echoes audio back for testing the audio pipeline.
/// Records audio, converts to WAV, and plays it back immediately.
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'audio_recorder_service.dart';
import 'audio_player_service.dart';
import 'audio_session_service.dart';

/// Echo controller state
enum EchoControllerState {
  idle,
  initializing,
  ready,
  recording,
  playing,
  error,
}

/// Echo Audio Controller
/// 
/// Simplified controller for testing audio pipeline without WebSocket.
/// Records audio and plays it back immediately (echo mode).
class EchoAudioController extends ChangeNotifier {
  final AudioRecorderService _recorder;
  final AudioPlayerService _player;
  final AudioSessionService _session;

  EchoControllerState _state = EchoControllerState.idle;
  String? _errorMessage;
  
  Timer? _amplitudeTimer;
  double _currentAmplitude = 0.0;
  Uint8List? _recordedAudio;

  /// Current state
  EchoControllerState get state => _state;
  
  /// Error message if state is error
  String? get errorMessage => _errorMessage;
  
  /// Check if recording
  bool get isRecording => _state == EchoControllerState.recording;
  
  /// Check if playing
  bool get isPlaying => _player.state == PlaybackState.playing;
  
  /// Check if ready
  bool get isReady => _state == EchoControllerState.ready;
  
  /// Current recording amplitude (0.0 to 1.0)
  double get currentAmplitude => _currentAmplitude;
  
  /// Get recorded audio data
  Uint8List? get recordedAudio => _recordedAudio;

  /// Constructor
  EchoAudioController({
    AudioRecorderService? recorder,
    AudioPlayerService? player,
    AudioSessionService? session,
  })  : _recorder = recorder ?? AudioRecorderService(),
        _player = player ?? AudioPlayerService(),
        _session = session ?? AudioSessionService();

  /// Initialize the controller
  Future<bool> initialize() async {
    debugPrint('[EchoAudioController] Initializing...');
    _setState(EchoControllerState.initializing);

    try {
      // Check and request microphone permission
      debugPrint('[EchoAudioController] Checking microphone permission...');
      final micStatus = await Permission.microphone.status;
      debugPrint('[EchoAudioController] Microphone permission status: $micStatus');
      
      if (!micStatus.isGranted) {
        debugPrint('[EchoAudioController] Requesting microphone permission...');
        final result = await Permission.microphone.request();
        debugPrint('[EchoAudioController] Microphone permission result: $result');
        
        if (!result.isGranted) {
          throw Exception('Microphone permission denied');
        }
      }

      // Configure audio session for dialogue
      debugPrint('[EchoAudioController] Configuring audio session...');
      final sessionConfigured = await _session.configureForDialogue();
      if (!sessionConfigured) {
        throw Exception('Failed to configure audio session');
      }
      debugPrint('[EchoAudioController] Audio session configured');

      // Activate audio session
      debugPrint('[EchoAudioController] Activating audio session...');
      final sessionActivated = await _session.activate();
      if (!sessionActivated) {
        throw Exception('Failed to activate audio session');
      }
      debugPrint('[EchoAudioController] Audio session activated');

      // Initialize recorder
      debugPrint('[EchoAudioController] Initializing recorder...');
      final recorderInitialized = await _recorder.initialize();
      if (!recorderInitialized) {
        throw Exception('Failed to initialize audio recorder');
      }
      debugPrint('[EchoAudioController] Recorder initialized');

      // Initialize player
      debugPrint('[EchoAudioController] Initializing player...');
      await _player.initialize();
      debugPrint('[EchoAudioController] Player initialized');

      _setState(EchoControllerState.ready);
      debugPrint('[EchoAudioController] Initialization complete');
      return true;
    } catch (e) {
      debugPrint('[EchoAudioController] Initialization failed: $e');
      _setError('Failed to initialize audio: $e');
      return false;
    }
  }

  /// Start recording
  Future<void> startRecording() async {
    debugPrint('[EchoAudioController] Starting recording...');
    
    if (!isReady) {
      debugPrint('[EchoAudioController] Not ready, initializing first...');
      final success = await initialize();
      if (!success) return;
    }

    try {
      // Check permission
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        throw Exception('Microphone permission denied');
      }

      _recordedAudio = null;
      
      await _recorder.startRecording(
        onAudioData: (data) {
          // Accumulate audio data
          if (_recordedAudio == null) {
            _recordedAudio = data;
          } else {
            final combined = Uint8List(_recordedAudio!.length + data.length);
            combined.setRange(0, _recordedAudio!.length, _recordedAudio!);
            combined.setRange(_recordedAudio!.length, combined.length, data);
            _recordedAudio = combined;
          }
          debugPrint('[EchoAudioController] Accumulated: ${_recordedAudio!.length} bytes');
        },
        onStateChanged: (isRecording) {
          debugPrint('[EchoAudioController] Recording state: $isRecording');
          if (isRecording) {
            _setState(EchoControllerState.recording);
            _startAmplitudeMonitoring();
          }
        },
      );
      debugPrint('[EchoAudioController] Recording started');
    } catch (e) {
      debugPrint('[EchoAudioController] Failed to start recording: $e');
      _setError('Failed to start recording: $e');
    }
  }

  /// Stop recording and play back
  Future<void> stopRecordingAndPlay() async {
    debugPrint('[EchoAudioController] Stopping recording...');
    
    try {
      await _recorder.stopRecording();
      _stopAmplitudeMonitoring();
      _currentAmplitude = 0.0;
      
      if (_recordedAudio != null && _recordedAudio!.isNotEmpty) {
        debugPrint('[EchoAudioController] Playing back: ${_recordedAudio!.length} bytes');
        await _playRecordedAudio();
      } else {
        debugPrint('[EchoAudioController] No audio recorded');
        _setState(EchoControllerState.ready);
      }
    } catch (e) {
      debugPrint('[EchoAudioController] Failed to stop recording: $e');
      _setError('Failed to stop recording: $e');
    }
  }

  /// Play recorded audio
  Future<void> _playRecordedAudio() async {
    try {
      _setState(EchoControllerState.playing);
      
      // Convert PCM to WAV format
      final wavData = _convertPcmToWav(_recordedAudio!, 16000);
      debugPrint('[EchoAudioController] Converted to WAV: ${wavData.length} bytes');
      
      await _player.playPcm(
        pcmData: _recordedAudio!,
        sampleRate: 16000,
        onStateChanged: (state) {
          debugPrint('[EchoAudioController] Playback state: $state');
          if (state == PlaybackState.completed ||
              state == PlaybackState.idle ||
              state == PlaybackState.error) {
            _setState(EchoControllerState.ready);
          }
        },
        onError: (error) {
          _setError('Playback error: $error');
        },
      );
    } catch (e) {
      debugPrint('[EchoAudioController] Failed to play audio: $e');
      _setError('Failed to play audio: $e');
    }
  }

  /// Convert PCM data to WAV format
  Uint8List _convertPcmToWav(Uint8List pcmData, int sampleRate) {
    const int numChannels = 1;
    const int bitsPerSample = 16;
    
    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;
    final int fileSize = 36 + dataSize;

    final buffer = BytesBuilder();

    // RIFF header
    buffer.add(Uint8List.fromList('RIFF'.codeUnits));
    buffer.add(_intToBytes(fileSize, 4));
    buffer.add(Uint8List.fromList('WAVE'.codeUnits));

    // fmt chunk
    buffer.add(Uint8List.fromList('fmt '.codeUnits));
    buffer.add(_intToBytes(16, 4));
    buffer.add(_intToBytes(1, 2));
    buffer.add(_intToBytes(numChannels, 2));
    buffer.add(_intToBytes(sampleRate, 4));
    buffer.add(_intToBytes(byteRate, 4));
    buffer.add(_intToBytes(blockAlign, 2));
    buffer.add(_intToBytes(bitsPerSample, 2));

    // data chunk
    buffer.add(Uint8List.fromList('data'.codeUnits));
    buffer.add(_intToBytes(dataSize, 4));
    buffer.add(pcmData);

    return buffer.toBytes();
  }

  /// Convert integer to bytes (little-endian)
  Uint8List _intToBytes(int value, int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = (value >> (i * 8)) & 0xFF;
    }
    return bytes;
  }

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  /// Get current volume
  double get volume => _player.volume;

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
    debugPrint('[EchoAudioController] Disposing...');
    _stopAmplitudeMonitoring();
    _recorder.dispose();
    _player.dispose();
    _session.dispose();
    super.dispose();
    debugPrint('[EchoAudioController] Disposed');
  }

  /// Set state and notify listeners
  void _setState(EchoControllerState newState) {
    if (_state != newState) {
      debugPrint('[EchoControllerState] State: $_state → $newState');
      _state = newState;
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Set error state
  void _setError(String message) {
    debugPrint('[EchoAudioController] Error: $message');
    _state = EchoControllerState.error;
    _errorMessage = message;
    notifyListeners();
  }
}