import 'package:flutter/widgets.dart';

import 'layer.dart';
import 'layer_interaction.dart';
import '/features/main_editor/services/ffmpeg_export_service.dart';

/// A layer that contains a video bubble overlay.
class VideoBubbleLayer extends Layer {
  /// Creates a new video bubble layer.
  VideoBubbleLayer({
    required this.path,
    required this.duration,
    this.startTime = 0,
    this.corner = VideoBubbleCorner.bottomRight,
    this.bubbleScale = 0.25,
    this.margin = 40,
    super.id,
    super.offset,
    super.rotation,
    super.scale,
    super.flipX,
    super.flipY,
  });

  /// The path to the video file.
  final String path;

  /// The duration of the video in milliseconds.
  final int duration;

  /// The start time of the video bubble in the main video in milliseconds.
  final int startTime;

  /// The corner position of the video bubble.
  final VideoBubbleCorner corner;

  /// The scale of the bubble relative to the main video width.
  final double bubbleScale;

  /// The margin from the edges in pixels.
  final int margin;

  /// Returns the end time of the video bubble in milliseconds.
  int get endTime => startTime + duration;

  /// Checks if this video bubble should be playing at the given time.
  ///
  /// [currentTime] is in milliseconds.
  bool isPlayingAtTime(int currentTime) {
    return currentTime >= startTime && currentTime < endTime;
  }

  bool get isVideoBubbleLayer => true;

  @override
  Map<String, dynamic> toMap({
    int? recordPosition,
    bool enableMinify = false,
    int maxDecimalPlaces = 10,
  }) {
    return {
      ...super.toMap(
        enableMinify: enableMinify,
        maxDecimalPlaces: maxDecimalPlaces,
      ),
      'path': path,
      'duration': duration,
      'startTime': startTime,
      'corner': corner.name,
      'bubbleScale': bubbleScale,
      'margin': margin,
      'type': 'videoBubble',
    };
  }

  /// Creates a copy of this object with the given fields replaced with the new values.
  @override
  VideoBubbleLayer copyWith({
    String? path,
    int? duration,
    int? startTime,
    VideoBubbleCorner? corner,
    double? bubbleScale,
    int? margin,
    String? id,
    String? groupId,
    Offset? offset,
    double? rotation,
    double? scale,
    bool? flipX,
    bool? flipY,
    LayerInteraction? interaction,
    Map<String, dynamic>? meta,
    BoxConstraints? boxConstraints,
  }) {
    return VideoBubbleLayer(
      path: path ?? this.path,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      corner: corner ?? this.corner,
      bubbleScale: bubbleScale ?? this.bubbleScale,
      margin: margin ?? this.margin,
      id: id ?? this.id,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }

  /// Creates a [VideoBubbleLayer] from a map.
  factory VideoBubbleLayer.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return VideoBubbleLayer(
      id: id,
      path: map['path'] ?? '',
      duration: map['duration'] ?? 0,
      startTime: map['startTime'] ?? 0,
      corner: VideoBubbleCorner.values.firstWhere(
        (e) => e.name == map['corner'],
        orElse: () => VideoBubbleCorner.bottomRight,
      ),
      bubbleScale: map['bubbleScale']?.toDouble() ?? 0.25,
      margin: map['margin'] ?? 40,
      offset: Offset(
        map['offset']?['dx'] ?? 0,
        map['offset']?['dy'] ?? 0,
      ),
      rotation: map['rotation'] ?? 0,
      scale: map['scale'] ?? 1,
      flipX: map['flipX'] ?? false,
      flipY: map['flipY'] ?? false,
    );
  }
}
