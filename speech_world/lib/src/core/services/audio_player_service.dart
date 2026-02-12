/// Audio Player Service
/// 
/// Handles audio playback for Dialogue Mode.
/// Plays PCM 16-bit audio at 24kHz mono from Gemini responses.
library;

import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';

/// Playback state enum
enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// Callback for playback state changes
typedef OnPlaybackStateChanged = void Function(PlaybackState state);

/// Callback for playback errors
typedef OnPlaybackError = void Function(String error);

/// Audio Player Service
/// 
/// Manages audio playback from Gemini responses.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  
  PlaybackState _state = PlaybackState.idle;
  StreamSubscription? _playerStateSubscription;
  
  /// Current playback state
  PlaybackState get state => _state;
  
  /// Check if currently playing
  bool get isPlaying => _state == PlaybackState.playing;
  
  /// Check if idle
  bool get isIdle => _state == PlaybackState.idle;

  /// Initialize the player
  Future<void> initialize() async {
    try {
      // Listen to player state changes
      _playerStateSubscription = _player.playerStateStream.listen((playerState) {
        final processingState = playerState.processingState;
        final playing = playerState.playing;
        
        if (processingState == ProcessingState.idle) {
          _state = PlaybackState.idle;
        } else if (processingState == ProcessingState.loading ||
                   processingState == ProcessingState.buffering) {
          _state = PlaybackState.loading;
        } else if (processingState == ProcessingState.ready) {
          _state = playing ? PlaybackState.playing : PlaybackState.paused;
        } else if (processingState == ProcessingState.completed) {
          _state = PlaybackState.completed;
        }
      });
    } catch (e) {
      throw Exception('Failed to initialize audio player: $e');
    }
  }

  /// Play audio from PCM data
  /// 
  /// [pcmData] - Raw PCM 16-bit audio data
  /// [sampleRate] - Sample rate in Hz (default: 24000 for Gemini output)
  Future<void> playPcm({
    required Uint8List pcmData,
    int sampleRate = 24000,
    OnPlaybackStateChanged? onStateChanged,
    OnPlaybackError? onError,
  }) async {
    try {
      _state = PlaybackState.loading;
      onStateChanged?.call(_state);

      // Convert PCM to WAV format (just_audio requires a supported format)
      final wavData = _convertPcmToWav(pcmData, sampleRate);
      
      // Create audio source from bytes
      final audioSource = AudioSource.uri(
        Uri.dataFromBytes(wavData),
      );

      // Set and play audio
      await _player.setAudioSource(audioSource);
      await _player.play();

      _state = PlaybackState.playing;
      onStateChanged?.call(_state);
    } catch (e) {
      _state = PlaybackState.error;
      onStateChanged?.call(_state);
      onError?.call('Failed to play audio: $e');
    }
  }

  /// Play audio from WAV file path
  Future<void> playFromFile(String filePath, {
    OnPlaybackStateChanged? onStateChanged,
    OnPlaybackError? onError,
  }) async {
    try {
      _state = PlaybackState.loading;
      onStateChanged?.call(_state);

      await _player.setFilePath(filePath);
      await _player.play();

      _state = PlaybackState.playing;
      onStateChanged?.call(_state);
    } catch (e) {
      _state = PlaybackState.error;
      onStateChanged?.call(_state);
      onError?.call('Failed to play audio: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _player.pause();
      _state = PlaybackState.paused;
    } catch (e) {
      throw Exception('Failed to pause playback: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    try {
      await _player.play();
      _state = PlaybackState.playing;
    } catch (e) {
      throw Exception('Failed to resume playback: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _player.stop();
      _state = PlaybackState.idle;
    } catch (e) {
      throw Exception('Failed to stop playback: $e');
    }
  }

  /// Set playback volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      throw Exception('Failed to set volume: $e');
    }
  }

  /// Get current volume
  double get volume => _player.volume;

  /// Get playback position
  Duration get position => _player.position;

  /// Get audio duration
  Duration? get duration => _player.duration;

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      throw Exception('Failed to seek: $e');
    }
  }

  /// Dispose the player
  Future<void> dispose() async {
    await _playerStateSubscription?.cancel();
    await _player.dispose();
    _state = PlaybackState.idle;
  }

  /// Convert PCM data to WAV format
  /// 
  /// just_audio requires a supported audio format.
  /// This method adds a WAV header to raw PCM data.
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
    buffer.add(_intToBytes(16, 4)); // Subchunk1Size (16 for PCM)
    buffer.add(_intToBytes(1, 2)); // AudioFormat (1 for PCM)
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
}

/// Singleton instance
final audioPlayerService = AudioPlayerService();
