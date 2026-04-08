import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/core/constants/int_constants.dart';
import '../layers/layer.dart';
import '../layers/layer_interaction.dart';
import 'timed_layer.dart';

/// A class representing a timed layer with emoji content.
///
/// TimedEmojiLayer is a subclass of [TimedLayer] that allows you to display
/// emoji on a canvas with specific timing. You can specify the emoji to
/// display, along with optional properties like offset, rotation, scale,
/// and timing information.
///
/// Example usage:
/// ```dart
/// TimedEmojiLayer(
///   emoji: '😀',
///   startTime: 0,
///   endTime: 5000,
///   offset: Offset(100.0, 100.0),
///   rotation: 45.0,
///   scale: 2.0,
/// );
/// ```
class TimedEmojiLayer extends TimedLayer {
  /// Creates an instance of TimedEmojiLayer.
  ///
  /// The [emoji], [startTime], and [endTime] parameters are required,
  /// and other properties are optional.
  TimedEmojiLayer({
    required super.startTime,
    required super.endTime,
    required this.emoji,
    super.offset,
    super.rotation,
    super.scale,
    super.id,
    super.flipX,
    super.flipY,
    super.interaction,
    super.meta,
    super.boxConstraints,
    super.key,
    super.groupId,
  });

  /// Factory constructor for creating a TimedEmojiLayer instance from a
  /// TimedLayer and a map.
  factory TimedEmojiLayer.fromMap(
    TimedLayer layer,
    Map<String, dynamic> map, {
    Function(String key)? keyConverter,
  }) {
    keyConverter ??= (String key) => key;

    /// Constructs and returns a TimedEmojiLayer instance with properties
    /// derived from the layer and map.
    return TimedEmojiLayer(
      id: layer.id,
      startTime: layer.startTime,
      endTime: layer.endTime,
      flipX: layer.flipX,
      flipY: layer.flipY,
      interaction: layer.interaction,
      offset: layer.offset,
      rotation: layer.rotation,
      scale: layer.scale,
      meta: layer.meta,
      groupId: layer.groupId,
      emoji: map[keyConverter('emoji')],
      boxConstraints: layer.boxConstraints,
    );
  }

  /// The emoji to display on the layer.
  String emoji;

  @override
  bool get isEmojiLayer => true;

  @override
  Map<String, dynamic> toMap({
    int maxDecimalPlaces = kMaxSafeDecimalPlaces,
    bool enableMinify = false,
  }) {
    return {
      ...super.toMap(
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      'emoji': emoji,
      'type': 'timedEmoji',
    };
  }

  @override
  Map<String, dynamic> toMapFromReference(
    Layer layer, {
    int maxDecimalPlaces = kMaxSafeDecimalPlaces,
    bool enableMinify = false,
  }) {
    return {
      ...super.toMapFromReference(
        layer,
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      if ((layer as TimedEmojiLayer).emoji != emoji) 'emoji': emoji,
    };
  }

  /// Creates a copy of this [TimedEmojiLayer] with the given fields replaced
  /// with new values.
  @override
  TimedEmojiLayer copyWith({
    int? startTime,
    int? endTime,
    String? emoji,
    Offset? offset,
    double? rotation,
    double? scale,
    bool? flipX,
    bool? flipY,
    LayerInteraction? interaction,
    Map<String, dynamic>? meta,
    BoxConstraints? boxConstraints,
    String? id,
    String? groupId,
  }) {
    return TimedEmojiLayer(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      emoji: emoji ?? this.emoji,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      interaction: interaction ?? this.interaction,
      meta: meta ?? this.meta,
      boxConstraints: boxConstraints ?? this.boxConstraints,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('emoji', emoji));
  }
}
