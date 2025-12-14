import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/audio_layer.dart';
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
    this.audioLayers,
    this.onDeleteLayer,
  });

  /// The editor configurations.
  final ProImageEditorConfigs configs;

  /// Callback when recording stops.
  final Function(String path, Duration duration) onStop;

  /// List of existing audio layers.
  final List<AudioLayer>? audioLayers;

  /// Callback when an audio layer is deleted.
  final Function(AudioLayer layer)? onDeleteLayer;

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late final AudioRecorderController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingAudioPath;

  @override
  void initState() {
    super.initState();
    _controller = AudioRecorderController();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingAudioPath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _playAudio(String path) async {
    if (_playingAudioPath == path) {
      await _audioPlayer.pause();
      setState(() {
        _playingAudioPath = null;
      });
    } else {
      await _audioPlayer.play(DeviceFileSource(path));
      setState(() {
        _playingAudioPath = path;
      });
    }
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
              if (widget.audioLayers != null &&
                  widget.audioLayers!.isNotEmpty) ...[
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.audioLayers!.length,
                    itemBuilder: (context, index) {
                      final layer = widget.audioLayers![index];
                      return ListTile(
                        leading: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        title: Text(
                          'Audio ${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${_formatDuration(Duration(milliseconds: layer.startTime))} - '
                          '${_formatDuration(Duration(milliseconds: layer.endTime))}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _playingAudioPath == layer.path
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () => _playAudio(layer.path),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                widget.onDeleteLayer?.call(layer);
                                setState(() {
                                  widget.audioLayers?.remove(layer);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 10),
              ],
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
