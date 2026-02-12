/// Audio Recorder Service
/// 
/// Handles audio recording from microphone for Dialogue Mode.
/// Records PCM 16-bit audio at 16kHz mono.
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Audio configuration for Dialogue Mode
class AudioConfig {
  /// Sample rate in Hz (16kHz required by Gemini)
  static const int sampleRate = 16000;
  
  /// Number of channels (mono)
  static const int numChannels = 1;
  
  /// Bit depth (16-bit PCM)
  static const int bitDepth = 16;
  
  /// Chunk size for streaming (bytes)
  static const int chunkSize = 3200; // 100ms at 16kHz/16bit
}

/// Callback for audio data
typedef OnAudioData = void Function(Uint8List data);

/// Callback for recording state changes
typedef OnRecordingStateChanged = void Function(bool isRecording);

/// Audio Recorder Service
/// 
/// Manages microphone recording and audio streaming.
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  
  bool _isRecording = false;
  bool _isInitialized = false;
  
  /// Check if currently recording
  bool get isRecording => _isRecording;
  
  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the recorder
  /// 
  /// Requests microphone permission and prepares the recorder.
  Future<bool> initialize() async {
    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Microphone permission denied');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      throw Exception('Failed to initialize audio recorder: $e');
    }
  }

  /// Start recording
  /// 
  /// Begins recording audio and streams PCM data through [onAudioData].
  Future<void> startRecording({
    required OnAudioData onAudioData,
    OnRecordingStateChanged? onStateChanged,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isRecording) {
      throw Exception('Already recording');
    }

    try {
      // Configure recording for PCM 16kHz mono
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: AudioConfig.sampleRate,
        numChannels: AudioConfig.numChannels,
      );

      // Start recording with stream
      final stream = await _recorder.startStream(config);
      
      _audioStreamSubscription = stream.listen(
        (data) {
          onAudioData(data);
        },
        onError: (error) {
          throw Exception('Audio stream error: $error');
        },
        onDone: () {
          _isRecording = false;
          onStateChanged?.call(false);
        },
      );

      _isRecording = true;
      onStateChanged?.call(true);
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Stop recording
  /// 
  /// Stops the audio recording and releases resources.
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      
      await _recorder.stop();
      _isRecording = false;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (!_isRecording) return;
    
    try {
      await _recorder.pause();
    } catch (e) {
      throw Exception('Failed to pause recording: $e');
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (!_isRecording) return;
    
    try {
      await _recorder.resume();
    } catch (e) {
      throw Exception('Failed to resume recording: $e');
    }
  }

  /// Dispose the recorder
  /// 
  /// Releases all resources. Call this when done with the service.
  Future<void> dispose() async {
    await stopRecording();
    await _recorder.dispose();
    _isInitialized = false;
  }

  /// Get recording amplitude (for visualization)
  /// 
  /// Returns current audio level (0.0 to 1.0) or null if not recording.
  Future<double?> getAmplitude() async {
    if (!_isRecording) return null;
    
    try {
      final amp = await _recorder.getAmplitude();
      // Convert dB to normalized value (0.0 to 1.0)
      // Typical range: -60dB (quiet) to 0dB (loud)
      final normalized = ((amp.current + 60) / 60).clamp(0.0, 1.0);
      return normalized;
    } catch (e) {
      return null;
    }
  }
}

/// Singleton instance
final audioRecorderService = AudioRecorderService();
