import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '/core/constants/int_constants.dart';
import '/core/platform/io/io_helper.dart';
import '/shared/services/import_export/types/widget_loader.dart';
import '/shared/utils/parser/int_parser.dart';
import '../editor_image.dart';
import '../layers/layer.dart';
import '../layers/layer_interaction.dart';
import '../layers/widget_layer.dart';
import 'timed_layer.dart';

export '/shared/services/import_export/models/widget_layer_export_configs.dart';

/// A class representing a timed layer with custom widget content.
///
/// TimedWidgetLayer is a subclass of [TimedLayer] that allows you to display
/// custom widget content with specific timing. You can specify properties
/// like offset, rotation, scale, and timing information.
///
/// Example usage:
/// ```dart
/// TimedWidgetLayer(
///   widget: MyCustomWidget(),
///   startTime: 0,
///   endTime: 5000,
///   offset: Offset(50.0, 50.0),
///   rotation: -30.0,
///   scale: 1.5,
/// );
/// ```
class TimedWidgetLayer extends TimedLayer {
  /// Creates an instance of TimedWidgetLayer.
  ///
  /// The [widget], [startTime], and [endTime] parameters are required,
  /// and other properties are optional.
  TimedWidgetLayer({
    required super.startTime,
    required super.endTime,
    required this.widget,
    super.offset,
    super.rotation,
    super.scale,
    super.id,
    super.flipX,
    super.flipY,
    super.interaction,
    this.exportConfigs = const WidgetLayerExportConfigs(),
    super.meta,
    super.boxConstraints,
    super.key,
    super.groupId,
  });

  /// Factory constructor for creating a TimedWidgetLayer instance from a
  /// TimedLayer, a map, and a list of widgets.
  factory TimedWidgetLayer.fromMap({
    required TimedLayer layer,
    required Map<String, dynamic> map,
    required List<Uint8List> widgetRecords,
    required WidgetLoader? widgetLoader,
    required Function(EditorImage editorImage)? requirePrecache,
    Function(String key)? keyConverter,
  }) {
    keyConverter ??= (String key) => key;

    /// Determines the position of the widget in the list.
    int widgetPosition = safeParseInt(
        map[keyConverter('recordPosition')] ?? map['listPosition'],
        fallback: -1);

    var exportConfigs =
        WidgetLayerExportConfigs.fromMap(map[keyConverter('exportConfigs')]);

    /// Widget to display a widget or a placeholder if not found.
    Widget widget = kDebugMode
        ? Text(
            'Widget $widgetPosition not found',
            style: const TextStyle(color: Color(0xFFF44336), fontSize: 48),
          )
        : const SizedBox.shrink();

    var defaultConstraints = const BoxConstraints(minWidth: 1, minHeight: 1);

    /// Updates the widget widget if the position is valid.
    if (exportConfigs.id != null) {
      assert(
        widgetLoader != null,
        'The `widgetLoader` must be defined when '
        'importing the widget layer by id',
      );
      widget = widgetLoader!(exportConfigs.id!, meta: exportConfigs.meta);
    } else if (exportConfigs.networkUrl != null) {
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.network(exportConfigs.networkUrl!),
      );
      requirePrecache?.call(EditorImage(networkUrl: exportConfigs.networkUrl));
    } else if (exportConfigs.assetPath != null) {
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.asset(exportConfigs.assetPath!),
      );
      requirePrecache?.call(EditorImage(assetPath: exportConfigs.assetPath));
    } else if (exportConfigs.fileUrl != null) {
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.file(File(exportConfigs.fileUrl!) as dynamic),
      );
      requirePrecache?.call(EditorImage(file: File(exportConfigs.fileUrl!)));
    } else if (widgetRecords.isNotEmpty &&
        widgetRecords.length > widgetPosition) {
      var bytes = widgetRecords[widgetPosition];
      widget = ConstrainedBox(
        constraints: defaultConstraints,
        child: Image.memory(bytes),
      );
      requirePrecache?.call(EditorImage(byteArray: bytes));
    }

    /// Constructs and returns a TimedWidgetLayer instance with properties
    /// derived from the layer and map.
    return TimedWidgetLayer(
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
      widget: widget,
      exportConfigs: exportConfigs,
      boxConstraints: layer.boxConstraints,
    );
  }

  /// The widget to display on the layer.
  Widget widget;

  /// Configuration settings for exporting a widget layer.
  ///
  /// This class holds the necessary configurations required for a custom
  /// widget import-loader.
  WidgetLayerExportConfigs exportConfigs;

  @override
  bool get isWidgetLayer => true;

  /// Converts this transform object to a Map suitable for representing a
  /// widget.
  ///
  /// Returns a Map representing the properties of this transform object,
  /// augmented with the specified [recordPosition] indicating the position of
  /// the widget in a list.
  @override
  Map<String, dynamic> toMap({
    int maxDecimalPlaces = kMaxSafeDecimalPlaces,
    bool enableMinify = false,
    int recordPosition = -1,
  }) {
    return {
      ...super.toMap(
        maxDecimalPlaces: maxDecimalPlaces,
        enableMinify: enableMinify,
      ),
      'exportConfigs': exportConfigs.toMap(),
      'recordPosition': recordPosition,
      'type': 'timedWidget',
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
      'exportConfigs': exportConfigs.toMap(),
    };
  }

  /// Creates a copy of this [TimedWidgetLayer] with the given fields replaced
  /// with new values.
  @override
  TimedWidgetLayer copyWith({
    int? startTime,
    int? endTime,
    Widget? widget,
    WidgetLayerExportConfigs? exportConfigs,
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
    return TimedWidgetLayer(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      widget: widget ?? this.widget,
      exportConfigs: exportConfigs ?? this.exportConfigs,
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
    properties
      ..add(DiagnosticsProperty<Widget>('widget', widget))
      ..add(DiagnosticsProperty<WidgetLayerExportConfigs>(
          'exportConfigs', exportConfigs));
  }
}
