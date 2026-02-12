/// Audio Session Service
/// 
/// Configures audio session for Dialogue Mode with AEC (Acoustic Echo Cancellation)
/// and NS (Noise Suppression) using the voiceChat mode.
library;

import 'dart:async';
import 'package:audio_session/audio_session.dart';

/// Audio interruption event
class AudioInterruptionEvent {
  /// Whether the interruption is beginning (true) or ending (false)
  final bool begin;
  
  /// Type of interruption
  final AudioInterruptionType type;
  
  const AudioInterruptionEvent({
    required this.begin,
    required this.type,
  });
}

/// Audio session configuration for Dialogue Mode
class AudioSessionService {
  AudioSession? _session;
  bool _isConfigured = false;
  final _interruptionController = StreamController<AudioInterruptionEvent>.broadcast();

  /// Check if session is configured
  bool get isConfigured => _isConfigured;

  /// Stream of audio interruption events
  Stream<AudioInterruptionEvent> get interruptionEvents => _interruptionController.stream;

  /// Initialize and configure audio session
  /// 
  /// Sets up the audio session for voice chat with:
  /// - Acoustic Echo Cancellation (AEC)
  /// - Noise Suppression (NS)
  /// - Low latency mode
  Future<void> initialize() async {
    try {
      _session = await AudioSession.instance;
      
      // Configure for voice chat
      // This enables AEC and NS on supported devices
      await _session!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
      ));
      
      // Listen to interruption events
      _session!.interruptionEventStream.listen((event) {
        _interruptionController.add(AudioInterruptionEvent(
          begin: event.begin,
          type: event.type,
        ));
      });
      
      _isConfigured = true;
    } catch (e) {
      throw Exception('Failed to initialize audio session: $e');
    }
  }

  /// Activate audio session
  /// 
  /// Should be called when starting Dialogue Mode.
  Future<void> activate() async {
    if (!_isConfigured) {
      await initialize();
    }

    try {
      // Request audio focus
      final result = await _session!.setActive(true);
      
      if (!result) {
        throw Exception('Failed to activate audio session');
      }
    } catch (e) {
      throw Exception('Failed to activate audio session: $e');
    }
  }

  /// Deactivate audio session
  /// 
  /// Should be called when stopping Dialogue Mode.
  Future<void> deactivate() async {
    if (_session == null) return;

    try {
      await _session!.setActive(false);
    } catch (e) {
      throw Exception('Failed to deactivate audio session: $e');
    }
  }

  /// Configure for playback only
  /// 
  /// Use this when only listening (not recording).
  Future<void> configureForPlayback() async {
    try {
      _session ??= await AudioSession.instance;
      
      await _session!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
      ));
      _isConfigured = true;
    } catch (e) {
      throw Exception('Failed to configure for playback: $e');
    }
  }

  /// Configure for recording only
  /// 
  /// Use this when only recording (not playing).
  Future<void> configureForRecording() async {
    try {
      _session ??= await AudioSession.instance;
      
      await _session!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.record,
      ));
      _isConfigured = true;
    } catch (e) {
      throw Exception('Failed to configure for recording: $e');
    }
  }

  /// Configure for dialogue mode (bidirectional)
  /// 
  /// This is the main configuration for Dialogue Mode.
  /// Enables both recording and playback with AEC.
  Future<void> configureForDialogue() async {
    try {
      _session ??= await AudioSession.instance;
      
      // Voice chat mode provides AEC and NS
      await _session!.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
      ));
      
      _isConfigured = true;
    } catch (e) {
      throw Exception('Failed to configure for dialogue: $e');
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    await deactivate();
    await _interruptionController.close();
    _isConfigured = false;
    _session = null;
  }
}

/// Singleton instance
final audioSessionService = AudioSessionService();
