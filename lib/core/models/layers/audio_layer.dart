import 'package:flutter/widgets.dart';

import 'layer.dart';
import 'layer_interaction.dart';

/// A layer that contains audio data.
class AudioLayer extends Layer {
  /// Creates a new audio layer.
  AudioLayer({
    required this.path,
    required this.duration,
    this.startTime = 0,
    super.id,
    super.offset,
    super.rotation,
    super.scale,
    super.flipX,
    super.flipY,
  });

  /// The path to the audio file.
  final String path;

  /// The duration of the audio in milliseconds.
  final int duration;

  /// The start time of the audio in the video in milliseconds.
  final int startTime;

  /// Returns the end time of the audio in milliseconds.
  int get endTime => startTime + duration;

  /// Checks if this audio should be playing at the given time.
  ///
  /// [currentTime] is in milliseconds.
  bool isPlayingAtTime(int currentTime) {
    return currentTime >= startTime && currentTime < endTime;
  }

  @override
  bool get isAudioLayer => true;

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
      'type': 'audio',
    };
  }

  /// Creates a copy of this object with the given fields replaced with the new values.
  @override
  AudioLayer copyWith({
    String? path,
    int? duration,
    int? startTime,
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
    return AudioLayer(
      path: path ?? this.path,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      id: id ?? this.id,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
    );
  }

  /// Creates an [AudioLayer] from a map.
  factory AudioLayer.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return AudioLayer(
      id: id,
      path: map['path'] ?? '',
      duration: map['duration'] ?? 0,
      startTime: map['startTime'] ?? 0,
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
