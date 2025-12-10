import 'package:flutter/material.dart';

import '/shared/widgets/timeline/time_range_selector_bar.dart';
import '/shared/widgets/timeline/time_range_selector_config.dart';
import '/shared/widgets/timeline/time_range_selector_style.dart';
import '../../../shared/widgets/video/select_timmer_range/video_editor_select_range_thumbnails.dart';

/// A timeline widget for timed text editing with video thumbnails.
///
/// This widget provides a professional timeline interface for selecting when
/// text should appear and disappear in a video, showing video thumbnails as
/// background.
class TimedTextTimelineBar extends StatelessWidget {
  /// Creates a [TimedTextTimelineBar] widget.
  const TimedTextTimelineBar({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    required this.theme,
    this.thumbnails,
    this.minDuration = 100,
  });

  /// The start time in milliseconds.
  final int startTime;

  /// The end time in milliseconds.
  final int endTime;

  /// The total duration of the timeline in milliseconds.
  final int totalDuration;

  /// Callback when the start time changes.
  final ValueChanged<int> onStartTimeChanged;

  /// Callback when the end time changes.
  final ValueChanged<int> onEndTimeChanged;

  /// The theme for styling the timeline.
  final ThemeData theme;

  /// Optional video thumbnails to display as background.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  /// Minimum duration for the selection in milliseconds.
  final int minDuration;

  /// Formats milliseconds to a readable time string (MM:SS.mmm).
  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final millis = duration.inMilliseconds.remainder(1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis}';
  }

  @override
  Widget build(BuildContext context) {
    // Create style for the timeline
    final timelineStyle = TimeRangeSelectorStyle(
      height: 48.0, // Reduced from 60
      handlerWidth: 8.0,
      handlerButtonSize: 16.0,
      handlerRadius: 8.0,
      borderWidth: 2.0,
      background: theme.colorScheme.primary,
      outsideAreaBackground: const Color(0x99000000),
      handlerColor: theme.colorScheme.primary,
      handlerIconColor: Colors.white,
      borderColor: theme.colorScheme.primary,
    );

    // Create config
    final config = TimeRangeSelectorConfig(
      totalDuration: totalDuration,
      startTime: startTime,
      endTime: endTime,
      minDuration: minDuration,
      maxDuration: totalDuration,
      minScale: 1.0,
      maxScale: 5.0,
      style: timelineStyle,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start: ${_formatTime(startTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Duration: ${_formatTime(endTime - startTime)}',
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  'End: ${_formatTime(endTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Timeline with thumbnails (no overlay)
            SizedBox(
              height: 48, // Reduced from 60
              child: TimeRangeSelectorBar(
                config: config,
                backgroundWidget: VideoEditorSelectRangeThumbnailBar(
                  thumbnails: thumbnails,
                  height: 48.0, // Reduced from 60
                  borderRadius: 8.0,
                ),
                onTimeRangeChanged: (startMs, endMs) {
                  onStartTimeChanged(startMs);
                  onEndTimeChanged(endMs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
