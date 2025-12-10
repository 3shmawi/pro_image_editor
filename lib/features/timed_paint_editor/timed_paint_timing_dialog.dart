import 'package:flutter/material.dart';

import '../../shared/widgets/video/select_timmer_range/video_editor_select_range_thumbnails.dart';
import '/shared/widgets/timeline/time_range_selector_bar.dart';
import '/shared/widgets/timeline/time_range_selector_config.dart';
import '/shared/widgets/timeline/time_range_selector_style.dart';
import '/shared/widgets/video/trimmer/video_editor_trim_thumbnail_bar.dart';

/// A dialog for setting timing on paint layers in video editing.
///
/// This dialog shows a timeline with video thumbnails and allows users
/// to set when a paint layer should appear and disappear in the video.
class TimedPaintTimingDialog extends StatefulWidget {
  /// Creates a [TimedPaintTimingDialog].
  const TimedPaintTimingDialog({
    super.key,
    required this.totalDuration,
    required this.theme,
    this.thumbnails,
    this.initialStartTime = 0,
    int? initialEndTime,
  }) : initialEndTime = initialEndTime ?? totalDuration;

  /// The total duration of the video in milliseconds.
  final int totalDuration;

  /// The theme for styling the dialog.
  final ThemeData theme;

  /// Optional video thumbnails to display in the timeline.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  /// Initial start time in milliseconds.
  final int initialStartTime;

  /// Initial end time in milliseconds.
  final int initialEndTime;

  @override
  State<TimedPaintTimingDialog> createState() => _TimedPaintTimingDialogState();
}

class _TimedPaintTimingDialogState extends State<TimedPaintTimingDialog> {
  late int _startTime;
  late int _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStartTime;
    _endTime = widget.initialEndTime;
  }

  /// Formats milliseconds to a readable time string (MM:SS.mmm).
  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final millis = duration.inMilliseconds.remainder(1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis}';
  }

  void _handleConfirm() {
    Navigator.of(context).pop(({
      'startTime': _startTime,
      'endTime': _endTime,
    }));
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Create style for the timeline
    final timelineStyle = TimeRangeSelectorStyle(
      height: 48.0,
      handlerWidth: 8.0,
      handlerButtonSize: 16.0,
      handlerRadius: 8.0,
      borderWidth: 2.0,
      background: widget.theme.colorScheme.primary,
      outsideAreaBackground: const Color(0x99000000),
      handlerColor: widget.theme.colorScheme.primary,
      handlerIconColor: Colors.white,
      borderColor: widget.theme.colorScheme.primary,
    );

    // Create config
    final config = TimeRangeSelectorConfig(
      totalDuration: widget.totalDuration,
      startTime: _startTime,
      endTime: _endTime,
      minDuration: 100,
      maxDuration: widget.totalDuration,
      minScale: 1.0,
      maxScale: 5.0,
      style: timelineStyle,
    );

    return Dialog(
      backgroundColor: widget.theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Set Paint Layer Timing',
              style: widget.theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose when this paint layer should appear in the video',
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: widget.theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Start: ${_formatTime(_startTime)}',
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: widget.theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    'End: ${_formatTime(_endTime)}',
                    style: widget.theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: widget.theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              'Duration: ${_formatTime(_endTime - _startTime)}',
              style: widget.theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Timeline
            SizedBox(
              height: 48,
              child: TimeRangeSelectorBar(
                config: config,
                backgroundWidget: VideoEditorSelectRangeThumbnailBar(
                  thumbnails: widget.thumbnails,
                  height: 48.0,
                  borderRadius: 8.0,
                ),
                onTimeRangeChanged: (startMs, endMs) {
                  setState(() {
                    _startTime = startMs;
                    _endTime = endMs;
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _handleCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: widget.theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
