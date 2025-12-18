import 'package:flutter/material.dart';

import '/core/models/layers/audio_layer.dart';
import '/core/models/layers/layer.dart';
import '/core/models/layers/video_bubble_layer.dart';
import '/core/models/timed_layers/timed_paint_layer.dart';
import '/core/models/timed_layers/timed_text_layer.dart';
import '/shared/widgets/video/select_timmer_range/video_editor_select_range_thumbnails.dart';

/// A timeline widget for visualizing and managing all timed layers.
///
/// This widget provides a professional timeline interface showing all timed
/// layers (audio, text, paint, and video bubble) with their start times,
/// durations, and positions relative to the video timeline.
class LayersTimelineBar extends StatelessWidget {
  /// Creates a [LayersTimelineBar] widget.
  const LayersTimelineBar({
    super.key,
    required this.audioLayers,
    required this.totalDuration,
    required this.currentTimeNotifier,
    required this.onLayerTap,
    required this.theme,
    this.thumbnails,
    this.timedTextLayers = const [],
    this.timedPaintLayers = const [],
    this.videoBubbleLayers = const [],
  });

  /// List of audio layers to display.
  final List<AudioLayer> audioLayers;

  /// List of timed text layers to display.
  final List<TimedTextLayer> timedTextLayers;

  /// List of timed paint layers to display.
  final List<TimedPaintLayer> timedPaintLayers;

  /// List of video bubble layers to display.
  final List<VideoBubbleLayer> videoBubbleLayers;

  /// The total duration of the video in milliseconds.
  final int totalDuration;

  /// The current playback time notifier in Duration.
  final ValueNotifier<Duration> currentTimeNotifier;

  /// Callback when any layer is tapped.
  /// The callback receives the tapped layer.
  final ValueChanged<Layer> onLayerTap;

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

  /// Calculates the timeline height based on the number of layers.
  /// Ensures each layer has enough space.
  double _calculateTimelineHeight(int totalLayers) {
    const double layerHeight = 28.0;
    const double layerSpacing = 4.0;
    const double minTimelineHeight = 80.0;
    const double paddingBottom = 8.0;
    
    // Calculate total height needed for all layers
    final calculatedHeight = (totalLayers * (layerHeight + layerSpacing)) + paddingBottom;
    
    // Return at least minimum height, or calculated height
    return calculatedHeight.clamp(minTimelineHeight, double.infinity);
  }


  @override
  Widget build(BuildContext context) {
    // Calculate total number of timed layers
    final totalLayers = audioLayers.length + 
                       timedTextLayers.length + 
                       timedPaintLayers.length + 
                       videoBubbleLayers.length;

    if (totalLayers == 0) {
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
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.layers,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                
                    _buildLayerCountChips(),
                    const Spacer(),
                    const SizedBox(width: 16),
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

              // Timeline view - Scrollable
              SizedBox(
                height: _calculateTimelineHeight(totalLayers) +40, // Fixed outer height
                child: SingleChildScrollView( 
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
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

                      // All timed layers - Dynamic height based on layer count
                      SizedBox(
                        height: _calculateTimelineHeight(totalLayers),
                        child: Stack(
                          children: [
                            // Background grid
                            CustomPaint(
                              size: Size(
                                MediaQuery.of(context).size.width - 32,
                                _calculateTimelineHeight(totalLayers),
                              ),
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

                            // All layer bars
                            ..._buildAllLayerBars(context, totalLayers),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds small chips showing count of each layer type.
  Widget _buildLayerCountChips() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (audioLayers.isNotEmpty)
          _buildCountChip(
            icon: Icons.audiotrack,
            count: audioLayers.length,
            color: Colors.blue,
          ),
        if (timedTextLayers.isNotEmpty) ...[
          const SizedBox(width: 4),
          _buildCountChip(
            icon: Icons.text_fields,
            count: timedTextLayers.length,
            color: Colors.green,
          ),
        ],
        if (timedPaintLayers.isNotEmpty) ...[
          const SizedBox(width: 4),
          _buildCountChip(
            icon: Icons.brush,
            count: timedPaintLayers.length,
            color: Colors.orange,
          ),
        ],
        if (videoBubbleLayers.isNotEmpty) ...[
          const SizedBox(width: 4),
          _buildCountChip(
            icon: Icons.video_library,
            count: videoBubbleLayers.length,
            color: Colors.purple,
          ),
        ],
      ],
    );
  }

  /// Builds a small chip showing layer type and count.
  Widget _buildCountChip({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds all layer bars from different layer types.
  List<Widget> _buildAllLayerBars(BuildContext context, int totalLayers) {
    final List<Widget> layerBars = [];
    int globalIndex = 0;

    // Add audio layers
    for (int i = 0; i < audioLayers.length; i++) {
      layerBars.add(
        _buildTimedLayerBar(
          context: context,
          startTime: audioLayers[i].startTime,
          duration: audioLayers[i].duration,
          label: _getFileName(audioLayers[i].path),
          icon: Icons.music_note,
          color: Colors.blue,
          index: globalIndex,
          totalLayers: totalLayers,
          onTap: () => onLayerTap(audioLayers[i]),
        ),
      );
      globalIndex++;
    }

    // Add timed text layers
    for (int i = 0; i < timedTextLayers.length; i++) {
      layerBars.add(
        _buildTimedLayerBar(
          context: context,
          startTime: timedTextLayers[i].startTime,
          duration: timedTextLayers[i].duration,
          label: timedTextLayers[i].text.length > 20 
              ? '${timedTextLayers[i].text.substring(0, 20)}...'
              : timedTextLayers[i].text,
          icon: Icons.text_fields,
          color: Colors.green,
          index: globalIndex,
          totalLayers: totalLayers,
          onTap: () => onLayerTap(timedTextLayers[i]),
        ),
      );
      globalIndex++;
    }

    // Add timed paint layers
    for (int i = 0; i < timedPaintLayers.length; i++) {
      layerBars.add(
        _buildTimedLayerBar(
          context: context,
          startTime: timedPaintLayers[i].startTime,
          duration: timedPaintLayers[i].duration,
          label: 'Drawing ${i + 1}',
          icon: Icons.brush,
          color: Colors.orange,
          index: globalIndex,
          totalLayers: totalLayers,
          onTap: () => onLayerTap(timedPaintLayers[i]),
        ),
      );
      globalIndex++;
    }

    // Add video bubble layers
    for (int i = 0; i < videoBubbleLayers.length; i++) {
      layerBars.add(
        _buildTimedLayerBar(
          context: context,
          startTime: videoBubbleLayers[i].startTime,
          duration: videoBubbleLayers[i].duration,
          label: _getFileName(videoBubbleLayers[i].path),
          icon: Icons.video_library,
          color: Colors.purple,
          index: globalIndex,
          totalLayers: totalLayers,
          onTap: () => onLayerTap(videoBubbleLayers[i]),
        ),
      );
      globalIndex++;
    }

    return layerBars;
  }

  /// Builds a timed layer bar for any layer type.
  Widget _buildTimedLayerBar({
    required BuildContext context,
    required int startTime,
    required int duration,
    required String label,
    required IconData icon,
    required Color color,
    required int index,
    required int totalLayers,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width - 32;
    final startPosition = (startTime / totalDuration) * screenWidth;
    final width = (duration / totalDuration) * screenWidth;

    // Calculate vertical position with better spacing
    const double layerHeight = 28.0; // Increased from ~20 to 28 for better visibility
    const double layerSpacing = 4.0;
    final topPosition = index * (layerHeight + layerSpacing);

    return Positioned(
      left: startPosition.clamp(0.0, screenWidth - 40),
      top: topPosition,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width.clamp(40.0, screenWidth),
          height: layerHeight,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
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

