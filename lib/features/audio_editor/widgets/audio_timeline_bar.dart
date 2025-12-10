import 'package:flutter/material.dart';

import '/core/models/layers/audio_layer.dart';
import '/shared/widgets/video/select_timmer_range/video_editor_select_range_thumbnails.dart';

/// A timeline widget for visualizing and managing multiple audio layers.
///
/// This widget provides a professional timeline interface showing all audio
/// layers with their start times, durations, and positions relative to the
/// video timeline.
class AudioTimelineBar extends StatelessWidget {
  /// Creates an [AudioTimelineBar] widget.
  const AudioTimelineBar({
    super.key,
    required this.audioLayers,
    required this.totalDuration,
    required this.currentTimeNotifier,
    required this.onAudioLayerTap,
    required this.theme,
    this.thumbnails,
  });

  /// List of audio layers to display.
  final List<AudioLayer> audioLayers;

  /// The total duration of the video in milliseconds.
  final int totalDuration;

  /// The current playback time notifier in Duration.
  final ValueNotifier<Duration> currentTimeNotifier;

  /// Callback when an audio layer is tapped.
  final ValueChanged<AudioLayer> onAudioLayerTap;

  /// The theme for styling the timeline.
  final ThemeData theme;

  /// Optional video thumbnails to display as background.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  /// Formats milliseconds to a readable time string (MM:SS).
  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Extracts filename from path.
  String _getFileName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  /// Generates a color for an audio layer based on its index.
  Color _getLayerColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (audioLayers.isEmpty) {
      return const SizedBox.shrink();
    }

    return ValueListenableBuilder<Duration>(
      valueListenable: currentTimeNotifier,
      builder: (context, currentTime, child) {
        final currentTimeMs = currentTime.inMilliseconds;
        
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.audiotrack,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Audio Layers (${audioLayers.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTime(currentTimeMs),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Timeline view
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Thumbnail background
                    if (thumbnails != null)
                      SizedBox(
                        height: 40,
                        child: ValueListenableBuilder<List<ImageProvider>?>(
                          valueListenable: thumbnails!,
                          builder: (context, thumbs, _) {
                            if (thumbs == null || thumbs.isEmpty) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }
                            return VideoEditorSelectRangeThumbnailBar(
                              thumbnails: thumbnails,
                              height: 40,
                              borderRadius: 4,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Audio layers
                    Expanded(
                      child: Stack(
                        children: [
                          // Background grid
                          CustomPaint(
                            size: const Size(double.infinity, double.infinity),
                            painter: _TimelineGridPainter(
                              totalDuration: totalDuration,
                              theme: theme,
                            ),
                          ),

                          // Current time indicator
                          if (totalDuration > 0)
                            Positioned(
                              left: (currentTimeMs / totalDuration) *
                                  (MediaQuery.of(context).size.width - 32),
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 2,
                                color: theme.colorScheme.error,
                              ),
                            ),

                          // Audio layer bars
                          ...audioLayers.asMap().entries.map((entry) {
                            final index = entry.key;
                            final layer = entry.value;
                            return _buildAudioLayerBar(
                              context,
                              layer,
                              index,
                              audioLayers.length,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioLayerBar(
    BuildContext context,
    AudioLayer layer,
    int index,
    int totalLayers,
  ) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final startPosition = (layer.startTime / totalDuration) * screenWidth;
    final width = (layer.duration / totalDuration) * screenWidth;
    final layerColor = _getLayerColor(index);

    // Calculate vertical position - stack layers
    final layerHeight = 60.0 / totalLayers.clamp(1, 3);
    final topPosition = (index % 3) * layerHeight;

    return Positioned(
      left: startPosition,
      top: topPosition,
      child: GestureDetector(
        onTap: () => onAudioLayerTap(layer),
        child: Container(
          width: width.clamp(40.0, screenWidth),
          height: layerHeight - 4,
          decoration: BoxDecoration(
            color: layerColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: layerColor,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  size: 12,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getFileName(layer.path),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing timeline grid.
class _TimelineGridPainter extends CustomPainter {
  _TimelineGridPainter({
    required this.totalDuration,
    required this.theme,
  });

  final int totalDuration;
  final ThemeData theme;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.dividerColor.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    // Draw vertical grid lines every second
    final secondsCount = (totalDuration / 1000).ceil();
    for (int i = 0; i <= secondsCount; i++) {
      final x = (i * 1000 / totalDuration) * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

