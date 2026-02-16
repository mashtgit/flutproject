/// Audio Session Service
/// 
/// Configures audio session for Dialogue Mode with AEC (Acoustic Echo Cancellation)
/// and NS (Noise Suppression) using the voiceChat mode.
library;

import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';

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
  Future<bool> initialize() async {
    try {
      debugPrint('[AudioSessionService] Initializing...');
      _session = await AudioSession.instance;
      
      // Configure for voice chat
      // This enables AEC and NS on supported devices
      final config = AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        // Android specific configuration
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      );
      
      await _session!.configure(config);
      
      // Listen to interruption events
      _session!.interruptionEventStream.listen((event) {
        _interruptionController.add(AudioInterruptionEvent(
          begin: event.begin,
          type: event.type,
        ));
      });
      
      _isConfigured = true;
      debugPrint('[AudioSessionService] Initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to initialize: $e');
      _isConfigured = false;
      return false;
    }
  }

  /// Activate audio session
  /// 
  /// Should be called when starting Dialogue Mode.
  Future<bool> activate() async {
    if (!_isConfigured) {
      final success = await initialize();
      if (!success) return false;
    }

    try {
      debugPrint('[AudioSessionService] Activating...');
      // Request audio focus
      final result = await _session!.setActive(true);
      
      if (!result) {
        debugPrint('[AudioSessionService] Failed to activate - no audio focus');
        return false;
      }
      
      debugPrint('[AudioSessionService] Activated successfully');
      return true;
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to activate: $e');
      return false;
    }
  }

  /// Deactivate audio session
  /// 
  /// Should be called when stopping Dialogue Mode.
  Future<void> deactivate() async {
    if (_session == null) return;

    try {
      debugPrint('[AudioSessionService] Deactivating...');
      await _session!.setActive(false);
      debugPrint('[AudioSessionService] Deactivated');
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to deactivate: $e');
    }
  }

  /// Configure for playback only
  /// 
  /// Use this when only listening (not recording).
  Future<bool> configureForPlayback() async {
    try {
      _session ??= await AudioSession.instance;
      
      await _session!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.media,
        ),
      ));
      _isConfigured = true;
      return true;
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to configure for playback: $e');
      return false;
    }
  }

  /// Configure for recording only
  /// 
  /// Use this when only recording (not playing).
  Future<bool> configureForRecording() async {
    try {
      _session ??= await AudioSession.instance;
      
      await _session!.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.record,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
      ));
      _isConfigured = true;
      return true;
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to configure for recording: $e');
      return false;
    }
  }

  /// Configure for dialogue mode (bidirectional)
  /// 
  /// This is the main configuration for Dialogue Mode.
  /// Enables both recording and playback with AEC.
  Future<bool> configureForDialogue() async {
    try {
      debugPrint('[AudioSessionService] Configuring for dialogue mode...');
      _session ??= await AudioSession.instance;
      
      // Voice chat mode provides AEC and NS
      final config = AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.allowBluetoothA2dp |
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        // Android specific configuration for voice communication
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      );
      
      await _session!.configure(config);
      _isConfigured = true;
      debugPrint('[AudioSessionService] Configured for dialogue mode');
      return true;
    } catch (e) {
      debugPrint('[AudioSessionService] Failed to configure for dialogue: $e');
      return false;
    }
  }

  /// Dispose the service
  Future<void> dispose() async {
    debugPrint('[AudioSessionService] Disposing...');
    await deactivate();
    await _interruptionController.close();
    _isConfigured = false;
    _session = null;
    debugPrint('[AudioSessionService] Disposed');
  }
}

/// Singleton instance
final audioSessionService = AudioSessionService();