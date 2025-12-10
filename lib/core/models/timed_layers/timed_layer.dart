// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/constants/int_constants.dart';
import '/shared/services/import_export/types/widget_loader.dart';
import '/shared/services/import_export/utils/key_minifier.dart';
import '/shared/utils/parser/bool_parser.dart';
import '/shared/utils/parser/double_parser.dart';
import '../editor_image.dart';
import '../layers/layer.dart';
import '../layers/layer_interaction.dart';
import 'timed_emoji_layer.dart';
import 'timed_paint_layer.dart';
import 'timed_text_layer.dart';
import 'timed_widget_layer.dart';

export 'timed_emoji_layer.dart';
export 'timed_paint_layer.dart';
export 'timed_text_layer.dart';
export 'timed_widget_layer.dart';

/// Represents a timed layer with start and end time properties.
///
/// This class extends the base [Layer] class and adds timing functionality,
/// allowing layers to be displayed only during specific time ranges.
/// This is particularly useful for video editing or time-based animations.
class TimedLayer extends Layer {
  /// Creates a new timed layer with optional properties.
  ///
  /// The [startTime] and [endTime] parameters define when this layer should
  /// be visible in the timeline. Times are in milliseconds.
  TimedLayer({
    required this.startTime,
    required this.endTime,
    GlobalKey? key,
    String? id,
    LayerInteraction? interaction,
    super.offset,
    super.rotation,
    super.scale,
    super.flipX,
    super.flipY,
    super.meta,
    super.boxConstraints,
    super.groupId,
  })  : assert(startTime >= 0, 'startTime must be non-negative'),
        assert(endTime > startTime, 'endTime must be greater than startTime'),
        super(
          key: key,
          id: id,
          interaction: interaction,
        );

  /// Factory constructor for creating a TimedLayer instance from a map.
  factory TimedLayer.fromMap(
    Map<String, dynamic> map, {
    List<Uint8List>? widgetRecords,
    WidgetLoader? widgetLoader,
    String? id,
    Function(EditorImage editorImage)? requirePrecache,
    EditorKeyMinifier? minifier,
  }) {
    var keyConverter = minifier?.convertLayerKey ?? (String key) => key;
    var keyInteractionConverter =
        minifier?.convertLayerInteractionKey ?? (String key) => key;

    BoxConstraints? boxConstraints;
    var constrainedMap = map[keyConverter('boxConstraints')];

    if (constrainedMap != null) {
      boxConstraints = BoxConstraints(
        minWidth: safeParseDouble(constrainedMap['minWidth']),
        minHeight: safeParseDouble(constrainedMap['minHeight']),
        maxWidth: safeParseDouble(constrainedMap['maxWidth'],
            fallback: double.infinity),
        maxHeight: safeParseDouble(constrainedMap['maxHeight'],
            fallback: double.infinity),
      );
    }

    // Parse timing information
    int startTime = safeParseDouble(map[keyConverter('startTime')]).toInt();
    int endTime = safeParseDouble(map[keyConverter('endTime')]).toInt();

    TimedLayer layer = TimedLayer(
      id: id,
      startTime: startTime,
      endTime: endTime,
      flipX: safeParseBool(map[keyConverter('flipX')]),
      flipY: safeParseBool(map[keyConverter('flipY')]),
      interaction: LayerInteraction.fromMap(
        map[keyConverter('interaction')] ?? {},
        keyConverter: keyInteractionConverter,
      ),
      meta: map[keyConverter('meta')],
      offset: Offset(safeParseDouble(map['x']), safeParseDouble(map['y'])),
      rotation: safeParseDouble(map[keyConverter('rotation')]),
      scale: safeParseDouble(map[keyConverter('scale')], fallback: 1),
      boxConstraints: boxConstraints,
      groupId: map[keyConverter('groupId')],
    );

    /// Determines the layer type from the map and returns the appropriate
    /// TimedLayer subclass.
    switch (map[keyConverter('type')]) {
      case 'timedText':
        return TimedTextLayer.fromMap(layer, map, keyConverter: keyConverter);
      case 'timedEmoji':
        return TimedEmojiLayer.fromMap(layer, map, keyConverter: keyConverter);
      case 'timedPaint':
        return TimedPaintLayer.fromMap(layer, map, minifier: minifier);
      case 'timedWidget':
      case 'timedSticker':
        return TimedWidgetLayer.fromMap(
          layer: layer,
          map: map,
          widgetRecords: widgetRecords ?? [],
          widgetLoader: widgetLoader,
          requirePrecache: requirePrecache,
          keyConverter: keyConverter,
        );
      default:
        return layer;
    }
  }

  /// The start time in milliseconds when this layer should become visible.
  int startTime;

  /// The end time in milliseconds when this layer should become invisible.
  int endTime;

  /// Returns the duration of this layer in milliseconds.
  int get duration => endTime - startTime;

  /// Checks if this layer should be visible at the given time.
  ///
  /// [currentTime] is in milliseconds.
  bool isVisibleAtTime(int currentTime) {
    return currentTime >= startTime && currentTime < endTime;
  }

  /// Indicates whether this layer is a [TimedLayer].
  bool get isTimedLayer => true;

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
      'startTime': startTime,
      'endTime': endTime,
      'type': 'timed',
    };
  }

  @override
  Map<String, dynamic> toMapFromReference(
    Layer layer, {
    int maxDecimalPlaces = kMaxSafeDecimalPlaces,
    bool enableMinify = false,
  }) {
    var timedLayer = layer as TimedLayer;
    return {
      ...super.toMapFromReference(
        layer,
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      if (timedLayer.startTime != startTime) 'startTime': startTime,
      if (timedLayer.endTime != endTime) 'endTime': endTime,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TimedLayer &&
        super == other &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return super.hashCode ^ startTime.hashCode ^ endTime.hashCode;
  }

  /// Creates a copy of this [TimedLayer] with the given fields replaced with
  /// new values.
  @override
  TimedLayer copyWith({
    int? startTime,
    int? endTime,
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
    return TimedLayer(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      interaction: interaction ?? this.interaction,
      meta: meta ?? this.meta,
      boxConstraints: boxConstraints ?? this.boxConstraints,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('startTime', startTime))
      ..add(IntProperty('endTime', endTime))
      ..add(IntProperty('duration', duration))
      ..add(FlagProperty('isTimedLayer', value: isTimedLayer, ifTrue: 'true'));
  }
}
