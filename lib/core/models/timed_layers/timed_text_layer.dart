import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/core/constants/int_constants.dart';
import '/shared/extensions/color_extension.dart';
import '/shared/extensions/num_extension.dart';
import '/shared/utils/parser/double_parser.dart';
import '/shared/utils/parser/int_parser.dart';
import '../layers/enums/layer_background_mode.dart';
import '../layers/layer.dart';
import '../layers/layer_interaction.dart';
import 'timed_layer.dart';

/// Represents a timed text layer with customizable properties and timing.
///
/// This class extends [TimedLayer] and adds text-specific properties,
/// allowing text to be displayed only during specific time ranges.
class TimedTextLayer extends TimedLayer {
  /// Creates a new timed text layer with customizable properties.
  ///
  /// The [text] parameter specifies the text content of the layer.
  /// The [startTime] and [endTime] parameters define when this layer should
  /// be visible in the timeline (in milliseconds).
  TimedTextLayer({
    required super.startTime,
    required super.endTime,
    required this.text,
    this.customSecondaryColor = false,
    this.hit = false,
    this.textStyle,
    this.colorMode = LayerBackgroundMode.backgroundAndColor,
    this.color = const Color(0xFF000000),
    this.background = const Color(0xFFFFFFFF),
    this.align = TextAlign.left,
    this.fontScale = 1.0,
    this.maxTextWidth,
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

  /// Factory constructor for creating a TimedTextLayer instance from a
  /// TimedLayer instance and a map.
  factory TimedTextLayer.fromMap(
    TimedLayer layer,
    Map<String, dynamic> map, {
    Function(String key)? keyConverter,
  }) {
    keyConverter ??= (String key) => key;

    /// Helper function to determine the text decoration style from a string.
    TextDecoration getDecoration(String decoration) {
      if (decoration.contains('combine')) {
        List<TextDecoration> decorations = [];

        if (decoration.contains('lineThrough')) {
          decorations.add(TextDecoration.lineThrough);
        }
        if (decoration.contains('overline')) {
          decorations.add(TextDecoration.overline);
        }
        if (decoration.contains('underline')) {
          decorations.add(TextDecoration.underline);
        }

        return TextDecoration.combine(decorations);
      } else {
        if (decoration.contains('lineThrough')) {
          return TextDecoration.lineThrough;
        } else if (decoration.contains('overline')) {
          return TextDecoration.overline;
        } else if (decoration.contains('underline')) {
          return TextDecoration.underline;
        }
      }

      return TextDecoration.none;
    }

    /// Optional properties for text styling from the map.
    String? fontFamily = map[keyConverter('fontFamily')] as String?;
    double? wordSpacing = tryParseDouble(map[keyConverter('wordSpacing')]);
    double? height = tryParseDouble(map[keyConverter('height')]);
    double? letterSpacing = tryParseDouble(map[keyConverter('letterSpacing')]);
    double? fontScale = tryParseDouble(map[keyConverter('fontScale')]) ?? 1.0;
    int? fontWeight = tryParseInt(map[keyConverter('fontWeight')]);
    String? fontStyle = map[keyConverter('fontStyle')] as String?;
    String? decoration = map[keyConverter('decoration')] as String?;

    return TimedTextLayer(
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
      boxConstraints: layer.boxConstraints,
      groupId: layer.groupId,
      text: map[keyConverter('text')] ?? '-',
      fontScale: fontScale,
      maxTextWidth: tryParseDouble(map[keyConverter('maxTextWidth')]),
      textStyle: fontFamily != null ||
              wordSpacing != null ||
              height != null ||
              letterSpacing != null ||
              fontWeight != null ||
              fontStyle != null ||
              decoration != null
          ? TextStyle(
              fontFamily: fontFamily,
              height: height,
              wordSpacing: wordSpacing,
              letterSpacing: letterSpacing,
              decoration: decoration != null ? getDecoration(decoration) : null,
              fontStyle: fontStyle != null
                  ? FontStyle.values
                      .firstWhere((element) => element.name == fontStyle)
                  : null,
              fontWeight: fontWeight != null
                  ? FontWeight.values
                      .firstWhere((element) => element.value == fontWeight)
                  : null,
            )
          : null,
      colorMode: LayerBackgroundMode.values.firstWhere(
          (element) => element.name == map[keyConverter!('colorMode')]),
      color: Color(map[keyConverter('color')]),
      background: Color(map[keyConverter('background')]),
      align: TextAlign.values
          .firstWhere((element) => element.name == map[keyConverter!('align')]),
      customSecondaryColor: map[keyConverter('customSecondaryColor')] ?? false,
    );
  }

  /// Flag that indicates if the layers hit box is triggered.
  bool hit;

  /// The text content of the layer.
  String text;

  /// The color mode for the text.
  LayerBackgroundMode colorMode;

  /// The text color.
  Color color;

  /// The background color for the text.
  Color background;

  /// This flag define if the secondary color is manually set.
  bool customSecondaryColor;

  /// The text alignment within the layer.
  TextAlign align;

  /// The font scale for text, to make text bigger or smaller.
  double fontScale;

  /// The maximum width that the text can occupy.
  ///
  /// If set, the text will be constrained to this width, and will wrap. If
  /// null, the text will not have a width constraint.
  double? maxTextWidth;

  /// A custom text style for the text. Be careful the editor allow not to
  /// import and export this style.
  TextStyle? textStyle;

  @override
  bool get isTextLayer => false;

  /// Indicates whether this layer is a timed text layer.
  @override
  bool get isTimedTextLayer => true;

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
      'text': text,
      'colorMode': LayerBackgroundMode.values[colorMode.index].name,
      'color': color.toHex(),
      'background': background.toHex(),
      'align': align.name,
      'fontScale': fontScale.roundSmart(maxDecimalPlaces),
      'type': 'timedText',
      if (maxTextWidth != null)
        'maxTextWidth': maxTextWidth?.roundSmart(maxDecimalPlaces),
      if (customSecondaryColor) 'customSecondaryColor': customSecondaryColor,
      if (textStyle?.fontFamily != null) 'fontFamily': textStyle?.fontFamily,
      if (textStyle?.fontStyle != null) 'fontStyle': textStyle?.fontStyle!.name,
      if (textStyle?.fontWeight != null)
        'fontWeight': textStyle?.fontWeight!.value,
      if (textStyle?.letterSpacing != null)
        'letterSpacing': textStyle?.letterSpacing?.roundSmart(maxDecimalPlaces),
      if (textStyle?.height != null)
        'height': textStyle?.height?.roundSmart(maxDecimalPlaces),
      if (textStyle?.wordSpacing != null)
        'wordSpacing': textStyle?.wordSpacing?.roundSmart(maxDecimalPlaces),
      if (textStyle?.decoration != null)
        'decoration': textStyle?.decoration.toString(),
    };
  }

  @override
  Map<String, dynamic> toMapFromReference(
    Layer layer, {
    int maxDecimalPlaces = kMaxSafeDecimalPlaces,
    bool enableMinify = false,
  }) {
    var timedTextLayer = layer as TimedTextLayer;
    return {
      ...super.toMapFromReference(
        layer,
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      if (timedTextLayer.text != text) 'text': text,
      if (timedTextLayer.fontScale != fontScale)
        'fontScale': fontScale.roundSmart(maxDecimalPlaces),
      if (timedTextLayer.color != color) 'color': color.toHex(),
      if (timedTextLayer.background != background)
        'background': background.toHex(),
      if (timedTextLayer.colorMode.name != colorMode.name)
        'colorMode': LayerBackgroundMode.values[colorMode.index].name,
      if (timedTextLayer.customSecondaryColor != customSecondaryColor)
        'customSecondaryColor': customSecondaryColor,
      if (timedTextLayer.textStyle?.fontFamily != textStyle?.fontFamily)
        'fontFamily': textStyle?.fontFamily,
      if (timedTextLayer.textStyle?.fontStyle != textStyle?.fontStyle)
        'fontStyle': textStyle?.fontStyle!.name,
      if (timedTextLayer.textStyle?.fontWeight != textStyle?.fontWeight)
        'fontWeight': textStyle?.fontWeight!.value,
      if (timedTextLayer.textStyle?.letterSpacing != textStyle?.letterSpacing)
        'letterSpacing': textStyle?.letterSpacing?.roundSmart(maxDecimalPlaces),
      if (timedTextLayer.textStyle?.height != textStyle?.height)
        'height': textStyle?.height?.roundSmart(maxDecimalPlaces),
      if (timedTextLayer.textStyle?.wordSpacing != textStyle?.wordSpacing)
        'wordSpacing': textStyle?.wordSpacing?.roundSmart(maxDecimalPlaces),
      if (timedTextLayer.textStyle?.decoration != textStyle?.decoration)
        'decoration': textStyle?.decoration.toString(),
      if (timedTextLayer.maxTextWidth != maxTextWidth)
        'maxTextWidth': maxTextWidth?.roundSmart(maxDecimalPlaces),
    };
  }

  /// Creates a copy of this [TimedTextLayer] with the given fields replaced
  /// with new values.
  @override
  TimedTextLayer copyWith({
    int? startTime,
    int? endTime,
    String? text,
    Color? color,
    Color? background,
    LayerBackgroundMode? colorMode,
    TextAlign? align,
    TextStyle? textStyle,
    double? fontScale,
    Offset? offset,
    double? rotation,
    double? scale,
    double? maxTextWidth,
    bool? hit,
    bool? flipX,
    bool? flipY,
    bool? customSecondaryColor,
    LayerInteraction? interaction,
    Map<String, dynamic>? meta,
    BoxConstraints? boxConstraints,
    String? id,
    String? groupId,
  }) {
    return TimedTextLayer(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      text: text ?? this.text,
      customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
      hit: hit ?? this.hit,
      textStyle: textStyle ?? this.textStyle,
      colorMode: colorMode ?? this.colorMode,
      color: color ?? this.color,
      background: background ?? this.background,
      align: align ?? this.align,
      fontScale: fontScale ?? this.fontScale,
      maxTextWidth: maxTextWidth ?? this.maxTextWidth,
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
      ..add(StringProperty('text', text))
      ..add(EnumProperty<LayerBackgroundMode>('colorMode', colorMode))
      ..add(ColorProperty('color', color))
      ..add(ColorProperty('background', background))
      ..add(DiagnosticsProperty<bool>(
          'customSecondaryColor', customSecondaryColor))
      ..add(EnumProperty<TextAlign>('align', align))
      ..add(DoubleProperty('fontScale', fontScale))
      ..add(DoubleProperty('maxTextWidth', maxTextWidth))
      ..add(DiagnosticsProperty<TextStyle>('textStyle', textStyle))
      ..add(DiagnosticsProperty<bool>('hasHit', hit));
  }
}
