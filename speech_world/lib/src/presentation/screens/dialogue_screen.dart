/// Dialogue Screen
/// 
/// Main UI for Dialogue Mode with language selection and audio controls.
/// Features: WebSocket connection, real-time audio streaming, VU meter visualization,
/// Smart VAD Gating state display, Barge-in indication.
library;

import 'package:flutter/material.dart';
import '../widgets/language_selector.dart';
import '../../core/config/languages.dart';
import '../../core/services/dialogue_audio_controller.dart';
import '../../core/services/vad_controller.dart';

/// Dialogue Screen
class DialogueScreen extends StatefulWidget {
  const DialogueScreen({super.key});

  @override
  State<DialogueScreen> createState() => _DialogueScreenState();
}

class _DialogueScreenState extends State<DialogueScreen> {
  late final DialogueAudioController _audioController;
  
  String _l1Code = defaultL1Language;
  String _l2Code = defaultL2Language;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _showBargeIn = false;

  @override
  void initState() {
    super.initState();
    _audioController = DialogueAudioController();
    _audioController.addListener(_onControllerUpdate);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final success = await _audioController.initialize();
      if (!success) {
        setState(() {
          _errorMessage = _audioController.errorMessage ?? 'Failed to initialize audio';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization error: $e';
      });
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      // Check for barge-in
      if (_audioController.vadState == VadState.speechDetected && 
          _audioController.isPlaying) {
        _showBargeIn = true;
        // Hide after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _showBargeIn = false;
            });
          }
        });
      }
      
      setState(() {});
    }
  }

  @override
  void dispose() {
    _audioController.removeListener(_onControllerUpdate);
    _audioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dialogue Mode'),
        centerTitle: true,
        actions: [
          // Connection status indicator
          _buildConnectionStatus(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Error message
              if (_errorMessage != null) _buildErrorMessage(),
              
              // Loading indicator
              if (_isInitializing)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Initializing audio...'),
                      ],
                    ),
                  ),
                )
              else ...[
                // Language selector
                LanguageSelector(
                  initialL1: _l1Code,
                  initialL2: _l2Code,
                  onChanged: (l1, l2) {
                    setState(() {
                      _l1Code = l1;
                      _l2Code = l2;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Status indicator
                _buildStatusIndicator(theme),
                const SizedBox(height: 8),
                
                // VAD State indicator
                if (_audioController.isRecording)
                  _buildVadIndicator(theme),
                const SizedBox(height: 16),
                
                // Audio visualization
                _buildAudioVisualization(),
                const SizedBox(height: 24),

                // Main control button
                _buildMainButton(),
                const SizedBox(height: 16),

                // Secondary controls
                if (_audioController.isConnected || _audioController.isRecording)
                  _buildSecondaryControls(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final isConnected = _audioController.isConnected;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isConnected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              color: isConnected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(50)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    String statusText;
    Color statusColor;
    
    switch (_audioController.state) {
      case AudioControllerState.idle:
      case AudioControllerState.ready:
        statusText = 'Ready to start';
        statusColor = Colors.grey;
        break;
      case AudioControllerState.connecting:
        statusText = 'Connecting...';
        statusColor = Colors.orange;
        break;
      case AudioControllerState.connected:
        statusText = 'Connected - Tap to speak';
        statusColor = Colors.blue;
        break;
      case AudioControllerState.recording:
        statusText = 'Listening...';
        statusColor = Colors.green;
        break;
      case AudioControllerState.playing:
        statusText = 'Playing response...';
        statusColor = Colors.purple;
        break;
      case AudioControllerState.error:
        statusText = 'Error';
        statusColor = Colors.red;
        break;
      case AudioControllerState.disconnected:
        statusText = 'Disconnected';
        statusColor = Colors.grey;
        break;
      default:
        statusText = 'Initializing...';
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
          // Barge-in indicator
          if (_showBargeIn) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'BARGE-IN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVadIndicator(ThemeData theme) {
    String vadText;
    Color vadColor;
    IconData vadIcon;
    
    switch (_audioController.vadState) {
      case VadState.idle:
        vadText = 'VAD: Waiting for speech...';
        vadColor = Colors.grey;
        vadIcon = Icons.mic_off;
        break;
      case VadState.speechDetected:
        vadText = 'VAD: Speech detected ✓';
        vadColor = Colors.green;
        vadIcon = Icons.mic;
        break;
      case VadState.speechEnding:
        vadText = 'VAD: Speech ending...';
        vadColor = Colors.orange;
        vadIcon = Icons.mic_none;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: vadColor.withAlpha(15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: vadColor.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(vadIcon, size: 16, color: vadColor),
          const SizedBox(width: 6),
          Text(
            vadText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: vadColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioVisualization() {
    if (!_audioController.isRecording) {
      return const SizedBox(height: 80);
    }

    // VU Meter visualization with VAD state
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedBuilder(
        animation: _audioController,
        builder: (context, child) {
          final amplitude = _audioController.currentAmplitude;
          final isVadGateOpen = _audioController.isVadGateOpen;
          
          return CustomPaint(
            size: const Size(double.infinity, 80),
            painter: _VUMeterPainter(
              amplitude: amplitude,
              isGateOpen: isVadGateOpen,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainButton() {
    final isActive = _audioController.isConnected || _audioController.isRecording;
    final isRecording = _audioController.isRecording;
    final isPlaying = _audioController.isPlaying;

    // Determine button appearance based on state
    Color buttonColor;
    IconData buttonIcon;
    String buttonLabel;

    if (isPlaying) {
      buttonColor = Colors.purple;
      buttonIcon = Icons.volume_up;
      buttonLabel = 'Playing';
    } else if (isRecording) {
      buttonColor = Colors.red;
      buttonIcon = Icons.mic;
      buttonLabel = 'Recording';
    } else if (isActive) {
      buttonColor = Colors.orange;
      buttonIcon = Icons.mic_none;
      buttonLabel = 'Tap to speak';
    } else {
      buttonColor = Colors.blue;
      buttonIcon = Icons.play_arrow;
      buttonLabel = 'Start';
    }

    return GestureDetector(
      onTapDown: isActive && !isPlaying ? (_) => _startRecording() : null,
      onTapUp: isRecording ? (_) => _stopRecording() : null,
      onTapCancel: isRecording ? () => _stopRecording() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isRecording ? 180 : 160,
        height: isRecording ? 180 : 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [buttonColor, buttonColor.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: buttonColor.withAlpha(80),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isPlaying ? null : _toggleSession,
            customBorder: const CircleBorder(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  buttonIcon,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  buttonLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        IconButton(
          onPressed: _stopSession,
          icon: const Icon(Icons.stop_circle, size: 48),
          color: Colors.red,
          tooltip: 'Stop session',
        ),
        const SizedBox(width: 16),
        // Volume control
        IconButton(
          onPressed: _showVolumeDialog,
          icon: const Icon(Icons.volume_up, size: 32),
          color: Colors.grey[600],
          tooltip: 'Adjust volume',
        ),
      ],
    );
  }

  void _toggleSession() async {
    if (_audioController.isConnected || _audioController.isRecording) {
      await _stopSession();
    } else {
      await _startSession();
    }
  }

  Future<void> _startSession() async {
    try {
      final success = await _audioController.startSession(
        l1Language: _l1Code,
        l2Language: _l2Code,
      );
      
      if (!success && mounted) {
        setState(() {
          _errorMessage = _audioController.errorMessage ?? 'Failed to start session';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error starting session: $e';
        });
      }
    }
  }

  Future<void> _stopSession() async {
    try {
      await _audioController.stopSession();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error stopping session: $e';
        });
      }
    }
  }

  void _startRecording() {
    if (!_audioController.isConnected) {
      debugPrint('[DialogueScreen] Cannot start recording - not connected');
      setState(() {
        _errorMessage = 'Not connected to server';
      });
      return;
    }
    
    try {
      debugPrint('[DialogueScreen] Starting recording...');
      _audioController.startRecording();
    } catch (e) {
      debugPrint('[DialogueScreen] Error starting recording: $e');
      setState(() {
        _errorMessage = 'Error starting recording: $e';
      });
    }
  }

  void _stopRecording() {
    try {
      debugPrint('[DialogueScreen] Stopping recording...');
      _audioController.stopRecording();
    } catch (e) {
      debugPrint('[DialogueScreen] Error stopping recording: $e');
      setState(() {
        _errorMessage = 'Error stopping recording: $e';
      });
    }
  }

  void _showVolumeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Playback Volume'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: _audioController.volume,
                onChanged: (value) {
                  _audioController.setVolume(value);
                  setState(() {});
                },
              ),
              Text('${(_audioController.volume * 100).round()}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

/// VU Meter Painter for audio visualization
class _VUMeterPainter extends CustomPainter {
  final double amplitude;
  final bool isGateOpen;

  _VUMeterPainter({
    required this.amplitude,
    required this.isGateOpen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final barCount = 20;
    final barWidth = size.width / (barCount * 2);
    final spacing = barWidth;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      // Calculate bar height based on amplitude and position
      final position = i / barCount;
      final barAmplitude = amplitude * (1 - position * 0.5);
      final barHeight = barAmplitude * size.height * 0.8;

      // Color based on VAD state and amplitude
      if (isGateOpen) {
        // Gate is open - show active colors
        if (amplitude > 0.7) {
          paint.color = Colors.red;
        } else if (amplitude > 0.4) {
          paint.color = Colors.orange;
        } else {
          paint.color = Colors.green;
        }
      } else {
        // Gate is closed - show muted colors
        paint.color = Colors.grey.withAlpha(100);
      }

      final x = (size.width - (barCount * (barWidth + spacing))) / 2 + 
                i * (barWidth + spacing);

      // Draw bar
      canvas.drawLine(
        Offset(x + barWidth / 2, centerY - barHeight / 2),
        Offset(x + barWidth / 2, centerY + barHeight / 2),
        paint,
      );
    }

    // Draw gate indicator
    final gatePaint = Paint()
      ..color = isGateOpen ? Colors.green : Colors.grey
      ..style = PaintingStyle.fill;

    // Gate status circle at the top
    canvas.drawCircle(
      Offset(size.width / 2, 10),
      6,
      gatePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VUMeterPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude || 
           oldDelegate.isGateOpen != isGateOpen;
  }
}
