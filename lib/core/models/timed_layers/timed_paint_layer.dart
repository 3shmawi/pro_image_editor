import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/core/constants/int_constants.dart';
import '/features/paint_editor/models/painted_model.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/services/import_export/utils/key_minifier.dart';
import '/shared/utils/parser/double_parser.dart';
import '../layers/layer.dart';
import '../layers/layer_interaction.dart';
import 'timed_layer.dart';

/// A class representing a timed layer with custom paint content.
///
/// TimedPaintLayer is a subclass of [TimedLayer] that allows you to display
/// custom-painted content on a canvas with specific timing. You can specify
/// the painted item and its raw size, along with optional properties like
/// offset, rotation, scale, and timing information.
///
/// Example usage:
/// ```dart
/// TimedPaintLayer(
///   item: CustomPaintedItem(),
///   rawSize: Size(200.0, 150.0),
///   startTime: 0,
///   endTime: 5000,
///   offset: Offset(50.0, 50.0),
///   rotation: -30.0,
///   scale: 1.5,
/// );
/// ```
class TimedPaintLayer extends TimedLayer {
  /// Creates an instance of TimedPaintLayer.
  ///
  /// The [item], [rawSize], [startTime], and [endTime] parameters are
  /// required, and other properties are optional.
  TimedPaintLayer({
    required super.startTime,
    required super.endTime,
    required this.item,
    required this.rawSize,
    required this.opacity,
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

  /// Factory constructor for creating a TimedPaintLayer instance from a
  /// TimedLayer and a map.
  factory TimedPaintLayer.fromMap(
    TimedLayer layer,
    Map<String, dynamic> map, {
    EditorKeyMinifier? minifier,
  }) {
    var keyConverter = minifier?.convertLayerKey ?? (String key) => key;

    /// Constructs and returns a TimedPaintLayer instance with properties
    /// derived from the layer and map.
    return TimedPaintLayer(
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
      opacity: safeParseDouble(map[keyConverter('opacity')], fallback: 1.0),
      rawSize: Size(
        safeParseDouble(map[keyConverter('rawSize')]?['w'], fallback: 0),
        safeParseDouble(map[keyConverter('rawSize')]?['h'], fallback: 0),
      ),
      item: PaintedModel.fromMap(
        map[keyConverter('item')] ?? {},
        keyConverter: minifier?.convertPaintKey,
      ),
      boxConstraints: layer.boxConstraints,
    );
  }

  /// The custom-painted item to display on the layer.
  PaintedModel item;

  /// The raw size of the painted item before applying scaling.
  final Size rawSize;

  /// The opacity level of the drawing.
  double opacity;

  /// Returns the size of the layer after applying the scaling factor.
  Size get size => Size(rawSize.width * scale, rawSize.height * scale);

  @override
  bool get isPaintLayer => true;

  @override
  bool get isTimedPaintLayer => true;

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
      'item': item.toMap(
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      'rawSize': {
        'w': rawSize.width.roundSmart(maxDecimalPlaces),
        'h': rawSize.height.roundSmart(maxDecimalPlaces),
      },
      'opacity': opacity.roundSmart(maxDecimalPlaces),
      'type': 'timedPaint',
    };
  }

  @override
  Map<String, dynamic> toMapFromReference(
    Layer layer, {
    int maxDecimalPlaces = kMaxSafeDecimalPlaces,
    bool enableMinify = false,
  }) {
    var timedPaintLayer = layer as TimedPaintLayer;
    return {
      ...super.toMapFromReference(
        layer,
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      if (timedPaintLayer.item != item)
        'item': item.toMap(
          maxDecimalPlaces: maxDecimalPlaces,
          enableMinify: enableMinify,
        ),
      if (timedPaintLayer.rawSize != rawSize)
        'rawSize': {
          'w': rawSize.width.roundSmart(maxDecimalPlaces),
          'h': rawSize.height.roundSmart(maxDecimalPlaces),
        },
      if (timedPaintLayer.opacity != opacity) 'opacity': opacity,
    };
  }

  /// Creates a copy of this [TimedPaintLayer] with the given fields replaced
  /// with new values.
  @override
  TimedPaintLayer copyWith({
    int? startTime,
    int? endTime,
    PaintedModel? item,
    Size? rawSize,
    double? opacity,
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
    return TimedPaintLayer(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      item: item ?? this.item,
      rawSize: rawSize ?? this.rawSize,
      opacity: opacity ?? this.opacity,
      offset: offset ?? this.offset,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      id: id ?? this.id,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      interaction: interaction ?? this.interaction,
      meta: meta ?? this.meta,
      boxConstraints: boxConstraints ?? this.boxConstraints,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('opacity', opacity))
      ..add(DiagnosticsProperty<Size>('rawSize', rawSize))
      ..add(DiagnosticsProperty<Size>('size', size));
    item.debugFillProperties(properties);
  }
}
