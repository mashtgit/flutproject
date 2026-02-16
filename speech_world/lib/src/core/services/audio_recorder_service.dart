/// Audio Recorder Service
/// 
/// Handles audio recording from microphone for Dialogue Mode.
/// Records PCM 16-bit audio at 16kHz mono.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
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
    debugPrint('[AudioRecorderService] Initializing...');
    
    try {
      // Check microphone permission
      debugPrint('[AudioRecorderService] Checking microphone permission...');
      final status = await Permission.microphone.request();
      debugPrint('[AudioRecorderService] Permission status: $status');
      
      if (status != PermissionStatus.granted) {
        debugPrint('[AudioRecorderService] Microphone permission denied');
        throw Exception('Microphone permission denied');
      }

      _isInitialized = true;
      debugPrint('[AudioRecorderService] Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[AudioRecorderService] Initialization error: $e');
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
    debugPrint('[AudioRecorderService] Starting recording...');
    
    if (!_isInitialized) {
      debugPrint('[AudioRecorderService] Not initialized, initializing...');
      await initialize();
    }

    if (_isRecording) {
      debugPrint('[AudioRecorderService] Already recording');
      throw Exception('Already recording');
    }

    try {
      // Configure recording for PCM 16kHz mono
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: AudioConfig.sampleRate,
        numChannels: AudioConfig.numChannels,
      );

      debugPrint('[AudioRecorderService] Starting stream with config: $config');
      
      // Start recording with stream
      final stream = await _recorder.startStream(config);
      
      _audioStreamSubscription = stream.listen(
        (data) {
          debugPrint('[AudioRecorderService] Audio chunk: ${data.length} bytes');
          onAudioData(data);
        },
        onError: (error) {
          debugPrint('[AudioRecorderService] Stream error: $error');
          throw Exception('Audio stream error: $error');
        },
        onDone: () {
          debugPrint('[AudioRecorderService] Stream done');
          _isRecording = false;
          onStateChanged?.call(false);
        },
      );

      _isRecording = true;
      onStateChanged?.call(true);
      debugPrint('[AudioRecorderService] Recording started successfully');
    } catch (e) {
      debugPrint('[AudioRecorderService] Failed to start recording: $e');
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
