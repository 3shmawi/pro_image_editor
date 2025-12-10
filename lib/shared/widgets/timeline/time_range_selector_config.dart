import 'time_range_selector_style.dart';

/// Configuration for the time range selector timeline.
///
/// This class defines the behavior and constraints of the timeline,
/// including duration limits, zoom settings, and visual style.
class TimeRangeSelectorConfig {
  /// Creates a [TimeRangeSelectorConfig] with the specified settings.
  const TimeRangeSelectorConfig({
    required this.totalDuration,
    this.startTime = 0,
    int? endTime,
    this.minDuration = 100,
    int? maxDuration,
    this.minScale = 1.0,
    this.maxScale = 5.0,
    this.invertMouseScroll = false,
    this.style = const TimeRangeSelectorStyle(),
  })  : endTime = endTime ?? totalDuration,
        maxDuration = maxDuration ?? totalDuration;

  /// The total duration of the timeline in milliseconds.
  final int totalDuration;

  /// The initial start time in milliseconds.
  final int startTime;

  /// The initial end time in milliseconds.
  final int endTime;

  /// The minimum allowed duration for the selection in milliseconds.
  final int minDuration;

  /// The maximum allowed duration for the selection in milliseconds.
  /// If null, defaults to [totalDuration].
  final int maxDuration;

  /// The minimum zoom scale factor.
  final double minScale;

  /// The maximum zoom scale factor.
  final double maxScale;

  /// Whether to invert the mouse scroll direction for zooming.
  final bool invertMouseScroll;

  /// The visual style configuration for the timeline.
  final TimeRangeSelectorStyle style;

  /// Creates a copy of this config with the given fields replaced.
  TimeRangeSelectorConfig copyWith({
    int? totalDuration,
    int? startTime,
    int? endTime,
    int? minDuration,
    int? maxDuration,
    double? minScale,
    double? maxScale,
    bool? invertMouseScroll,
    TimeRangeSelectorStyle? style,
  }) {
    return TimeRangeSelectorConfig(
      totalDuration: totalDuration ?? this.totalDuration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      minDuration: minDuration ?? this.minDuration,
      maxDuration: maxDuration ?? this.maxDuration,
      minScale: minScale ?? this.minScale,
      maxScale: maxScale ?? this.maxScale,
      invertMouseScroll: invertMouseScroll ?? this.invertMouseScroll,
      style: style ?? this.style,
    );
  }
}
