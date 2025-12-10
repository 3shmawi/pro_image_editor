import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/core/models/editor_configs/text_editor_configs.dart';
import '/core/models/timed_layers/timed_text_layer.dart';
import '../../../../features/text_editor/widgets/rounded_background_text/rounded_background_text.dart';

/// A widget representing a timed text layer in the editor.
///
/// This widget renders a timed text layer with the same visual appearance
/// as a regular text layer, but with timing information for video editing.
class LayerWidgetTimedTextItem extends StatelessWidget {
  /// Creates a [LayerWidgetTimedTextItem] with the given timed text layer
  /// and editor configurations.
  const LayerWidgetTimedTextItem({
    super.key,
    required this.layer,
    required this.textEditorConfigs,
    required this.showMoveCursor,
    required this.onHitChanged,
  });

  /// The timed text layer represented by this widget.
  final TimedTextLayer layer;

  /// Configuration settings for the text editor.
  final TextEditorConfigs textEditorConfigs;

  /// Notifies whether the move cursor should be shown.
  final ValueNotifier<bool> showMoveCursor;

  /// Callback function that is triggered when a hit status changes.
  ///
  /// The [onHitChanged] function takes a boolean parameter [hasHit] which
  /// indicates whether a hit has occurred (true) or not (false).
  final Function(bool hasHit) onHitChanged;

  void _handleLayerHit(bool hasHit) {
    // Update hit detection and cursor visibility state.
    if (layer.hit != hasHit || showMoveCursor.value != hasHit) {
      layer.hit = hasHit;
      showMoveCursor.value = hasHit;
    }
    layer.hit = hasHit;
    onHitChanged(hasHit);
  }

  @override
  Widget build(BuildContext context) {
    var fontSize = textEditorConfigs.initFontSize * layer.scale;
    var style = TextStyle(
      fontSize: fontSize * layer.fontScale,
      color: layer.color,
      overflow: TextOverflow.ellipsis,
    );

    final maxTextWidth = layer.maxTextWidth;

    return RoundedBackgroundText(
      enableHitBoxCorrection: true,
      maxTextWidth:
          maxTextWidth == null ? double.infinity : maxTextWidth * layer.scale,
      onHitTestResult: _handleLayerHit,
      layer.text.toString(),
      backgroundColor: layer.background,
      textAlign: layer.align,
      style: layer.textStyle?.copyWith(
            fontSize: style.fontSize,
            fontWeight: style.fontWeight,
            color: style.color,
            fontFamily: style.fontFamily,
          ) ??
          style,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    layer.debugFillProperties(properties);
  }
}
