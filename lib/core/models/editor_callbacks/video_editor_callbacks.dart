import '../video/trim_duration_span_model.dart';

/// Defines callback functions for handling video editor events.
class VideoEditorCallbacks {
  /// Creates an instance of [VideoEditorCallbacks].
  ///
  /// Allows defining custom callbacks for play, pause, mute toggle,
  /// trim span updates, and seeking.
  VideoEditorCallbacks({
    this.onPlay,
    this.onPause,
    this.onMuteToggle,
    this.onTrimSpanUpdate,
    this.onTrimSpanEnd,
    this.onSeek,
  });

  /// Callback triggered when the video starts playing.
  final Function()? onPlay;

  /// Callback triggered when the video is paused.
  final Function()? onPause;

  /// Callback triggered when the mute state is toggled.
  ///
  /// Receives a boolean indicating whether the video is muted.
  final Function(bool isMuted)? onMuteToggle;

  /// Callback triggered when the trim duration span is updated.
  ///
  /// Provides the new [TrimDurationSpan].
  final Function(TrimDurationSpan durationSpan)? onTrimSpanUpdate;

  /// Callback triggered when the trim duration span selection ends.
  ///
  /// Provides the final [TrimDurationSpan].
  final Function(TrimDurationSpan durationSpan)? onTrimSpanEnd;

  /// Callback triggered when seeking to a specific position in the video.
  ///
  /// Receives a [Duration] indicating the target position.
  final Future<void> Function(Duration position)? onSeek;

  /// Creates a copy with modified editor callbacks.
  VideoEditorCallbacks copyWith({
    Function()? onPlay,
    Function()? onPause,
    Function(bool isMuted)? onMuteToggle,
    Function(TrimDurationSpan durationSpan)? onTrimSpanUpdate,
    Function(TrimDurationSpan durationSpan)? onTrimSpanEnd,
    Future<void> Function(Duration position)? onSeek,
  }) {
    return VideoEditorCallbacks(
      onPlay: onPlay ?? this.onPlay,
      onPause: onPause ?? this.onPause,
      onMuteToggle: onMuteToggle ?? this.onMuteToggle,
      onTrimSpanUpdate: onTrimSpanUpdate ?? this.onTrimSpanUpdate,
      onTrimSpanEnd: onTrimSpanEnd ?? this.onTrimSpanEnd,
      onSeek: onSeek ?? this.onSeek,
    );
  }
}
