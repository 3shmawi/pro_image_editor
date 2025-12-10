import 'package:flutter/material.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '../controllers/audio_recorder_controller.dart';

/// A value notifier for keeping the original audio.
/// when adding audio layers
final keepOriginalAudio = ValueNotifier<bool>(false);

/// A widget for recording audio.
class AudioRecorderWidget extends StatefulWidget {
  /// Creates a new audio recorder widget.
  const AudioRecorderWidget({
    super.key,
    required this.configs,
    required this.onStop,
  });

  /// The editor configurations.
  final ProImageEditorConfigs configs;

  /// Callback when recording stops.
  final Function(String path, Duration duration) onStop;

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late final AudioRecorderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AudioRecorderController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(_controller.duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_controller.isRecording) ...[
                    IconButton(
                      icon: Icon(
                        _controller.isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: () {
                        if (_controller.isPaused) {
                          _controller.resume();
                        } else {
                          _controller.pause();
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.stop,
                        color: Colors.red,
                        size: 48,
                      ),
                      onPressed: () async {
                        final path = await _controller.stop();
                        if (path != null) {
                          widget.onStop(path, _controller.duration);
                        }
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(
                        Icons.mic,
                        color: Colors.red,
                        size: 48,
                      ),
                      onPressed: () {
                        _controller.start();
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Toggle for using original audio
              ValueListenableBuilder(
                  valueListenable: keepOriginalAudio,
                  builder: (context, keepAudio, child) {
                    return SwitchListTile(
                      title: const Text(
                        'Keep original audio as background',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        keepAudio
                            ? 'Original audio will be kept'
                            : 'Original audio will be replaced',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      value: keepAudio,
                      onChanged: (value) {
                        keepOriginalAudio.value = value;
                      },
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
            ],
          ),
        );
      },
    );
  }
}
