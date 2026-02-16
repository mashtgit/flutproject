/// Echo Test Screen
/// 
/// Test screen for audio pipeline without WebSocket/Vertex AI.
/// Records audio and plays it back immediately to verify audio works.
library;

import 'package:flutter/material.dart';
import '../../core/services/echo_audio_controller.dart';

/// Echo Test Screen
class EchoTestScreen extends StatefulWidget {
  const EchoTestScreen({super.key});

  @override
  State<EchoTestScreen> createState() => _EchoTestScreenState();
}

class _EchoTestScreenState extends State<EchoTestScreen> {
  late final EchoAudioController _controller;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = EchoAudioController();
    _controller.addListener(_onControllerUpdate);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final success = await _controller.initialize();
      if (!success) {
        setState(() {
          _errorMessage = _controller.errorMessage ?? 'Failed to initialize audio';
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
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Test (Echo Mode)'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
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
                // Status indicator
                _buildStatusIndicator(theme),
                const SizedBox(height: 24),
                
                // Audio visualization
                _buildAudioVisualization(),
                const SizedBox(height: 24),

                // Instructions
                _buildInstructions(),
                const SizedBox(height: 24),

                // Main control button
                _buildMainButton(),
                const SizedBox(height: 16),

                // Volume control
                _buildVolumeControl(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(height: 8),
            Text(
              'Echo Test Mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This mode tests the audio pipeline locally. '
              'Press and hold the button, speak, then release. '
              'Your voice will be played back.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.orange.shade800),
            ),
          ],
        ),
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
    
    switch (_controller.state) {
      case EchoControllerState.ready:
        statusText = 'Ready - Hold to speak';
        statusColor = Colors.green;
        break;
      case EchoControllerState.recording:
        statusText = 'Recording...';
        statusColor = Colors.red;
        break;
      case EchoControllerState.playing:
        statusText = 'Playing...';
        statusColor = Colors.blue;
        break;
      case EchoControllerState.error:
        statusText = 'Error';
        statusColor = Colors.red;
        break;
      case EchoControllerState.initializing:
        statusText = 'Initializing...';
        statusColor = Colors.orange;
        break;
      default:
        statusText = 'Idle';
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
        ],
      ),
    );
  }

  Widget _buildAudioVisualization() {
    if (!_controller.isRecording) {
      return const SizedBox(height: 100);
    }

    // VU Meter visualization
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final amplitude = _controller.currentAmplitude;
          return CustomPaint(
            size: const Size(double.infinity, 100),
            painter: _VUMeterPainter(amplitude: amplitude),
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return const Text(
      'Press and hold the microphone button, speak clearly, then release to hear your voice played back.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildMainButton() {
    final isRecording = _controller.isRecording;
    final isPlaying = _controller.isPlaying;

    // Determine button appearance
    Color buttonColor;
    IconData buttonIcon;
    String buttonLabel;

    if (isPlaying) {
      buttonColor = Colors.blue;
      buttonIcon = Icons.volume_up;
      buttonLabel = 'Playing';
    } else if (isRecording) {
      buttonColor = Colors.red;
      buttonIcon = Icons.mic;
      buttonLabel = 'Recording';
    } else {
      buttonColor = Colors.orange;
      buttonIcon = Icons.mic_none;
      buttonLabel = 'Hold to speak';
    }

    return GestureDetector(
      onTapDown: !isPlaying ? (_) => _startRecording() : null,
      onTapUp: isRecording ? (_) => _stopRecording() : null,
      onTapCancel: isRecording ? () => _stopRecording() : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isRecording ? 200 : 180,
        height: isRecording ? 200 : 180,
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
            onTap: null, // Handled by GestureDetector
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
                    fontSize: 16,
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

  Widget _buildVolumeControl() {
    return Column(
      children: [
        const Text(
          'Playback Volume',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_down, color: Colors.grey),
            SizedBox(
              width: 200,
              child: Slider(
                value: _controller.volume,
                onChanged: (value) {
                  _controller.setVolume(value);
                  setState(() {});
                },
              ),
            ),
            const Icon(Icons.volume_up, color: Colors.grey),
          ],
        ),
        Text(
          '${(_controller.volume * 100).round()}%',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  void _startRecording() {
    if (_controller.isPlaying) return;
    
    try {
      debugPrint('[EchoTestScreen] Starting recording...');
      _controller.startRecording();
    } catch (e) {
      debugPrint('[EchoTestScreen] Error starting recording: $e');
      setState(() {
        _errorMessage = 'Error starting recording: $e';
      });
    }
  }

  void _stopRecording() {
    try {
      debugPrint('[EchoTestScreen] Stopping recording...');
      _controller.stopRecordingAndPlay();
    } catch (e) {
      debugPrint('[EchoTestScreen] Error stopping recording: $e');
      setState(() {
        _errorMessage = 'Error stopping recording: $e';
      });
    }
  }
}

/// VU Meter Painter for audio visualization
class _VUMeterPainter extends CustomPainter {
  final double amplitude;

  _VUMeterPainter({required this.amplitude});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final barCount = 20;
    final barWidth = size.width / (barCount * 2);
    final spacing = barWidth;
    final centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      // Calculate bar height based on amplitude and position
      final position = i / barCount;
      final barAmplitude = amplitude * (1 - position * 0.3);
      final barHeight = barAmplitude * size.height * 0.9;

      // Color gradient from green to yellow to red
      if (amplitude > 0.8) {
        paint.color = Colors.red;
      } else if (amplitude > 0.5) {
        paint.color = Colors.orange;
      } else {
        paint.color = Colors.green;
      }

      final x = (size.width - (barCount * (barWidth + spacing))) / 2 + 
                i * (barWidth + spacing);

      // Draw bar with rounded corners
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _VUMeterPainter oldDelegate) {
    return oldDelegate.amplitude != amplitude;
  }
}