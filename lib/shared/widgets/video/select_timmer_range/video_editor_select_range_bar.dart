import 'package:flutter/material.dart';

import '../trimmer/video_editor_play_time_indicator.dart';
import '/core/models/video/trim_duration_span_model.dart';
import '/shared/widgets/timeline/time_range_selector_bar.dart';
import '/shared/widgets/timeline/time_range_selector_config.dart';
import '/shared/widgets/timeline/time_range_selector_style.dart';
import '../video_editor_configurable.dart';
import 'video_editor_select_range_thumbnails.dart';

/// A widget representing the trim bar in the video editor.
///
/// This allows users to select and adjust the trim duration of the video.
class VideoEditorSelectRangeBar extends StatefulWidget {
  /// Creates a [VideoEditorSelectRangeBar] widget.
  const VideoEditorSelectRangeBar({super.key});

  @override
  State<VideoEditorSelectRangeBar> createState() =>
      _VideoEditorSelectRangeBarState();
}

class _VideoEditorSelectRangeBarState extends State<VideoEditorSelectRangeBar> {
  VideoEditorConfigurable get _player => VideoEditorConfigurable.of(context);

  int get _videoDuration => _player.controller.videoDuration.inMicroseconds;

  bool _isUpdatingSelectRangeBar = false;

  @override
  Widget build(BuildContext context) {
    if (_player.widgets.trimBar != null) return _player.widgets.trimBar!;

    var style = _player.style;

    // Convert video editor style to TimeRangeSelectorStyle
    final timelineStyle = TimeRangeSelectorStyle(
      height: style.trimBarHeight,
      handlerWidth: style.trimBarHandlerWidth,
      handlerButtonSize: style.trimBarHandlerButtonSize,
      handlerRadius: style.trimBarHandlerRadius,
      borderWidth: style.trimBarBorderWidth,
      background: style.trimBarBackground,
      outsideAreaBackground: style.trimBarOutsideAreaBackground,
      handlerColor: style.trimBarColor,
      handlerIconColor: style.trimBarBackground,
      borderColor: style.trimBarBackground,
    );

    // Get current trim span
    final trimSpan = _player.controller.trimDurationSpanNotifier.value;
    final startMs = _player.controller.playTimeNotifier.value.inMicroseconds;
    final endMs = trimSpan.end.inMicroseconds;

    // Calculate min/max durations
    final minDurationMs = _player.configs.minTrimDuration.inMicroseconds;
    final maxDurationMs =
        _player.configs.maxTrimDuration?.inMicroseconds ?? _videoDuration;

    // Create config
    final config = TimeRangeSelectorConfig(
      totalDuration: _videoDuration,
      startTime: startMs,
      endTime: endMs,
      minDuration: minDurationMs,
      maxDuration: maxDurationMs,
      minScale: _player.configs.trimBarMinScale,
      maxScale: _player.configs.trimBarMaxScale,
      invertMouseScroll: _player.configs.trimBarInvertMouseScroll,
      style: timelineStyle,
    );

    return TimeRangeSelectorBar(
      config: config,
      backgroundWidget: const VideoEditorSelectRangeThumbnailBar(),
      showPlayTimeIndicator: !_isUpdatingSelectRangeBar,
      playTimeIndicator: ValueListenableBuilder(
        valueListenable: _player.controller.trimDurationSpanNotifier,
        builder: (_, durationSpan, __) {
          final barWidth = (endMs - startMs) / _videoDuration;

          return VideoEditorPlayTimeIndicator(
            areaWidth: barWidth * 1000, // Approximate width, will be adjusted
          );
        },
      ),
      onTimeRangeChanged: (startMs, endMs) {
        final startTime = Duration(microseconds: startMs);
        final endTime = Duration(microseconds: endMs);

        final span = TrimDurationSpan(
          start: Duration(seconds: startTime.inSeconds),
          end: Duration(seconds: endTime.inSeconds),
        );

        _player.controller.setTrimSpan(span);
        _player.showTrimTimeSpanNotifier.value = true;

        setState(() {
          _isUpdatingSelectRangeBar = true;
        });
      },
      onTimeRangeChangeEnd: (startMs, endMs) {
        _player.callbacks.onTrimSpanEnd?.call(
          TrimDurationSpan(
            start: Duration(microseconds: startMs),
            end: Duration(microseconds: endMs),
          ),
        );

        setState(() {
          _isUpdatingSelectRangeBar = false;
        });

        // Hide trim time span after delay
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted) {
            _player.showTrimTimeSpanNotifier.value = false;
          }
        });
      },
    );
  }
}
