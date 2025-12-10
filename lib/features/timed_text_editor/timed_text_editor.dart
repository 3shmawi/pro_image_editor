// Dart imports:
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../text_editor/widgets/text_editor_input.dart';
import '/core/mixins/converted_callbacks.dart';
import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/core/models/timed_layers/timed_text_layer.dart';
import '/features/text_editor/widgets/text_editor_appbar.dart';
import '/features/text_editor/widgets/text_editor_bottom_bar.dart';
import '/pro_image_editor.dart';
import '/shared/extensions/color_extension.dart';
import 'widgets/timed_text_timeline_bar.dart';

/// A StatefulWidget that provides a timed text editing interface for adding
/// and editing text layers with timing information.
///
/// This editor extends the functionality of the regular text editor by adding
/// start and end time controls, allowing text to appear and disappear at
/// specific times in a timeline.
class TimedTextEditor extends StatefulWidget with SimpleConfigsAccess {
  /// Creates a `TimedTextEditor` widget.
  ///
  /// The [heroTag], [layer], [i18n], [customWidgets], and [imageEditorTheme]
  /// parameters are required.
  const TimedTextEditor({
    super.key,
    this.heroTag,
    this.layer,
    this.callbacks = const ProImageEditorCallbacks(),
    this.configs = const ProImageEditorConfigs(),
    this.scaleFactor = 1.0,
    this.imageSize = Size.zero,
    this.totalDuration = 0,
    this.thumbnails,
    required this.theme,
  });

  @override
  final ProImageEditorConfigs configs;

  @override
  final ProImageEditorCallbacks callbacks;

  /// A unique hero tag for the image.
  final String? heroTag;

  /// The theme configuration for the editor.
  final ThemeData theme;

  /// The timed text layer data to be edited, if any.
  final TimedTextLayer? layer;

  /// The size of the image being edited, used for boundary text wrapping.
  final Size imageSize;

  /// A factor by which the textfield is scaled.
  ///
  /// This value is used to adjust the size of the text in the editor.
  /// A value of 1.0 means no scaling, while values greater than 1.0
  /// increase the size and values less than 1.0 decrease the size.
  final double scaleFactor;

  /// The total duration of the timeline in milliseconds.
  ///
  /// This is used to constrain the end time of the layer and provide
  /// context for the timeline UI.
  final int totalDuration;

  /// Optional video thumbnails to display in the timeline.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  @override
  createState() => TimedTextEditorState();
}

/// The state class for the `TimedTextEditor` widget.
class TimedTextEditorState extends State<TimedTextEditor>
    with
        ImageEditorConvertedConfigs,
        ImageEditorConvertedCallbacks,
        SimpleConfigsAccessState {
  late final StreamController<void> _rebuildController;

  /// Controller for managing text input.
  final TextEditingController textCtrl = TextEditingController();

  /// Node for managing focus on the text input.
  final FocusNode focusNode = FocusNode();

  /// Alignment of the text.
  late TextAlign align;

  /// Style applied to the selected text.
  late TextStyle selectedTextStyle;

  /// Mode for managing the background color of the text layer.
  late LayerBackgroundMode backgroundColorMode;

  /// Represents the dimensions of the body.
  Size editorBodySize = Size.infinite;

  late double _fontScale;
  final double _cursorWidth = 2.0;

  /// Start time of the text layer in milliseconds.
  late int _startTime;

  /// End time of the text layer in milliseconds.
  late int _endTime;

  /// Gets the start time in milliseconds.
  int get startTime => _startTime;

  /// Sets the start time in milliseconds.
  ///
  /// Ensures that start time is non-negative and less than end time.
  set startTime(int value) {
    if (value < 0) return;
    if (value >= _endTime) return;
    setState(() {
      _startTime = value;
    });
  }

  /// Gets the end time in milliseconds.
  int get endTime => _endTime;

  /// Sets the end time in milliseconds.
  ///
  /// Ensures that end time is greater than start time and within total
  /// duration.
  set endTime(int value) {
    if (value <= _startTime) return;
    if (widget.totalDuration > 0 && value > widget.totalDuration) return;
    setState(() {
      _endTime = value;
    });
  }

  /// Gets the duration of the text layer in milliseconds.
  int get duration => _endTime - _startTime;

  double? get _maxTextWidth {
    if (textEditorConfigs.enableImageBoundaryTextWrap &&
        widget.imageSize != Size.zero) {
      return widget.imageSize.width - 32 - _cursorWidth;
    }
    return textEditorConfigs.enableAutoOverflow
        ? editorBodySize.width - 32 - _cursorWidth
        : null;
  }

  /// Gets the primary color.
  Color get primaryColor => _primaryColor;
  late Color _primaryColor = textEditorConfigs.initialPrimaryColor;
  set primaryColor(Color color) {
    setState(() {
      _primaryColor = color;
      textEditorCallbacks?.handleColorChanged(color.toHex());
    });
  }

  /// Gets the secondary color.
  Color get secondaryColor => _secondaryColor ?? getContrastColor(primaryColor);
  late Color? _secondaryColor = textEditorConfigs.initialSecondaryColor;
  set secondaryColor(Color color) {
    setState(() {
      _secondaryColor = color;
    });
  }

  @override
  void initState() {
    super.initState();
    _rebuildController = StreamController.broadcast();
    align = textEditorConfigs.initialTextAlign;
    _fontScale = textEditorConfigs.initFontScale;
    backgroundColorMode = textEditorConfigs.initialBackgroundColorMode;

    selectedTextStyle = widget.layer?.textStyle ??
        textEditorConfigs.customTextStyles?.first ??
        textEditorConfigs.defaultTextStyle;

    // Initialize timing
    _startTime = widget.layer?.startTime ?? 0;
    _endTime = widget.layer?.endTime ??
        (widget.totalDuration > 0 ? widget.totalDuration : 5000);

    _initializeFromLayer();

    textEditorCallbacks?.onInit?.call();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      textEditorCallbacks?.onAfterViewInit?.call();
    });
  }

  @override
  void dispose() {
    _rebuildController.close();
    textCtrl.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    _rebuildController.add(null);
    textEditorCallbacks?.handleUpdateUI();
    super.setState(fn);
  }

  /// Initializes the text editor from the provided timed text layer data.
  void _initializeFromLayer() {
    if (widget.layer != null) {
      textCtrl.text = widget.layer!.text;
      align = widget.layer!.align;
      _fontScale = widget.layer!.fontScale;
      backgroundColorMode = widget.layer!.colorMode;
      if (widget.layer!.customSecondaryColor) {
        _primaryColor = widget.layer!.color;
        _secondaryColor = widget.layer!.background;
      } else {
        _primaryColor = backgroundColorMode == LayerBackgroundMode.background
            ? widget.layer!.background
            : widget.layer!.color;
      }
    }
  }

  /// Calculates the contrast color for a given color.
  Color getContrastColor(Color color) {
    int d = color.computeLuminance() > 0.5 ? 0 : 255;

    return Color.fromRGBO(d, d, d, color.a);
  }

  /// Gets the text color based on the selected color mode.
  Color get _textColor {
    switch (backgroundColorMode) {
      case LayerBackgroundMode.onlyColor:
      case LayerBackgroundMode.backgroundAndColor:
        return primaryColor;
      case LayerBackgroundMode.background:
        return secondaryColor;
      default:
        return primaryColor;
    }
  }

  /// Gets the background color based on the selected color mode.
  Color get _backgroundColor {
    switch (backgroundColorMode) {
      case LayerBackgroundMode.onlyColor:
        return Colors.transparent;
      case LayerBackgroundMode.backgroundAndColor:
        return secondaryColor;
      case LayerBackgroundMode.background:
        return primaryColor;
      default:
        return secondaryColor.withValues(alpha: 0.5);
    }
  }

  /// Gets the text font size based on the selected font scale.
  double get _textFontSize {
    return textEditorConfigs.initFontSize * _fontScale;
  }

  /// Toggles the text alignment between left, center, and right.
  void toggleTextAlign() {
    TextAlign nextTextAlign(TextAlign currentAlign) {
      switch (currentAlign) {
        case TextAlign.left:
          return TextAlign.center;
        case TextAlign.center:
          return TextAlign.right;
        case TextAlign.right:
        default:
          return TextAlign.left;
      }
    }

    align = nextTextAlign(align);
    textEditorCallbacks?.handleTextAlignChanged(align);
    setState(() {});
  }

  /// Toggles the background mode between various color modes.
  void toggleBackgroundMode() {
    LayerBackgroundMode nextBackgroundMode(LayerBackgroundMode currentMode) {
      switch (currentMode) {
        case LayerBackgroundMode.onlyColor:
          return LayerBackgroundMode.backgroundAndColor;
        case LayerBackgroundMode.backgroundAndColor:
          return LayerBackgroundMode.background;
        case LayerBackgroundMode.background:
          return LayerBackgroundMode.backgroundAndColorWithOpacity;
        case LayerBackgroundMode.backgroundAndColorWithOpacity:
          return LayerBackgroundMode.onlyColor;
      }
    }

    backgroundColorMode = nextBackgroundMode(backgroundColorMode);
    textEditorCallbacks?.handleBackgroundModeChanged(backgroundColorMode);
    setState(() {});
  }

  /// Gets the current font scale.
  double get fontScale => _fontScale;

  /// Sets the font scale to a new value.
  ///
  /// The new value is adjusted to one decimal place before being set.
  /// After setting the new value, the state is updated and the
  /// [textEditorCallbacks] are notified of the change.
  ///
  /// [value] - The new font scale value.
  set fontScale(double value) {
    _fontScale = (value * 10).ceilToDouble() / 10;
    setState(() {});
    textEditorCallbacks?.handleFontScaleChanged(value);
  }

  /// Displays a range slider for adjusting the font scale.
  ///
  /// This method shows a range slider in a modal bottom sheet for adjusting
  /// the font scale of the text.
  void openFontScaleBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: textEditorConfigs.style.fontScaleBottomSheetBackground,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${i18n.textEditor.fontScale}: ${_fontScale.toStringAsFixed(1)}x',
                    style: textEditorConfigs.style.fontSizeBottomSheetTitle,
                  ),
                  Slider(
                    value: _fontScale,
                    min: textEditorConfigs.minFontScale,
                    max: textEditorConfigs.maxFontScale,
                    divisions: ((textEditorConfigs.maxFontScale -
                                textEditorConfigs.minFontScale) /
                            0.1)
                        .round(),
                    onChanged: (value) {
                      setModalState(() {
                        fontScale = value;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Update the current text style.
  void setTextStyle(TextStyle style) {
    setState(() {
      selectedTextStyle = style;
    });
  }

  /// Closes the editor without applying changes.
  void close() {
    Navigator.pop(context);
    textEditorCallbacks?.handleCloseEditor();
  }

  /// Handles the "Done" action, either by applying changes or closing the
  /// editor.
  void done() {
    if (textCtrl.text.trim().isNotEmpty || widget.layer != null) {
      TimedTextLayer layer = TimedTextLayer(
        startTime: _startTime,
        endTime: _endTime,
        text: textCtrl.text.trim(),
        background: _backgroundColor,
        color: _textColor,
        align: align,
        fontScale: _fontScale,
        colorMode: backgroundColorMode,
        textStyle: selectedTextStyle,
        customSecondaryColor: _secondaryColor != null,
        maxTextWidth: (textEditorConfigs.enableAutoOverflow ||
                textEditorConfigs.enableImageBoundaryTextWrap)
            ? _maxTextWidth
            : null,
      );

      Navigator.of(context).pop(layer);
    } else {
      Navigator.of(context).pop();
    }
    textEditorCallbacks?.handleDone();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ExtendedPopScope(
          canPop: textEditorConfigs.enableGesturePop,
          child: Theme(
            data: widget.theme.copyWith(
                tooltipTheme:
                    widget.theme.tooltipTheme.copyWith(preferBelow: true)),
            child: SafeArea(
              top: textEditorConfigs.safeArea.top,
              bottom: textEditorConfigs.safeArea.bottom,
              left: textEditorConfigs.safeArea.left,
              right: textEditorConfigs.safeArea.right,
              child: Scaffold(
                backgroundColor: textEditorConfigs.style.background,
                appBar: _buildAppBar(constraints),
                body: _buildBody(),
                bottomNavigationBar: _buildBottomBar(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the app bar for the timed text editor.
  PreferredSizeWidget? _buildAppBar(BoxConstraints constraints) {
    return TextEditorAppBar(
      textEditorConfigs: textEditorConfigs,
      i18n: i18n.textEditor,
      onClose: close,
      onDone: done,
      align: align,
      onToggleTextAlign: toggleTextAlign,
      onOpenFontScaleBottomSheet: openFontScaleBottomSheet,
      onToggleBackgroundMode: toggleBackgroundMode,
      designMode: designMode,
      constraints: constraints,
    );
  }

  /// Builds the bottom navigation bar of the timed text editor.
  /// Returns a [Widget] representing the bottom navigation bar.
  Widget? _buildBottomBar() {
    if (isDesktop &&
        widget.configs.textEditor.customTextStyles?.isNotEmpty == false) {
      return const SizedBox(height: kBottomNavigationBarHeight);
    }

    return null;
  }

  /// Builds the body of the timed text editor.
  Widget _buildBody() {
    return LayoutBuilder(builder: (_, constraints) {
      editorBodySize = constraints.biggest;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: textEditorConfigs.enableTapOutsideToSave ? done : null,
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, child: _buildTextField()),
            _buildTimeline(),
            if (textEditorConfigs.showSelectFontStyleBottomBar)
              Positioned(
                bottom: 160, // Move up to make room for timeline
                left: 0,
                right: 0,
                height: kBottomNavigationBarHeight,
                child: TextEditorBottomBar(
                  configs: widget.configs,
                  selectedStyle: selectedTextStyle,
                  onFontChange: setTextStyle,
                ),
              ),
          ],
        ),
      );
    });
  }

  /// Builds the timeline widget for controlling start and end times.
  Widget _buildTimeline() {
    return TimedTextTimelineBar(
      startTime: _startTime,
      endTime: _endTime,
      totalDuration: widget.totalDuration > 0 ? widget.totalDuration : _endTime,
      thumbnails: widget.thumbnails,
      onStartTimeChanged: (value) {
        startTime = value;
      },
      onEndTimeChanged: (value) {
        endTime = value;
      },
      theme: widget.theme,
    );
  }

  /// Builds the text field for text input.
  Widget _buildTextField() {
    return TextEditorInput(
      callbacks: textEditorCallbacks,
      configs: textEditorConfigs,
      heroTag: widget.heroTag,
      align: align,
      backgroundColor: _backgroundColor,
      textCtrl: textCtrl,
      scaleFactor: widget.scaleFactor,
      focusNode: focusNode,
      i18n: i18n.textEditor,
      layer: widget.layer,
      selectedTextStyle: selectedTextStyle,
      textColor: _textColor,
      textFontSize: _textFontSize,
      maxWidth: _maxTextWidth ?? double.infinity,
      cursorWidth: _cursorWidth,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);

    properties
      ..add(StringProperty('heroTag', widget.heroTag))
      ..add(DoubleProperty('scaleFactor', widget.scaleFactor))
      ..add(DiagnosticsProperty<TimedTextLayer?>('layer', widget.layer))
      ..add(DiagnosticsProperty<Size>('imageSize', widget.imageSize))
      ..add(IntProperty('totalDuration', widget.totalDuration))
      ..add(DiagnosticsProperty<ThemeData>('theme', widget.theme))
      ..add(DiagnosticsProperty<TextAlign>('align', align))
      ..add(DiagnosticsProperty<TextStyle>(
          'selectedTextStyle', selectedTextStyle))
      ..add(EnumProperty<LayerBackgroundMode>(
          'backgroundColorMode', backgroundColorMode))
      ..add(DoubleProperty('fontScale', _fontScale))
      ..add(ColorProperty('primaryColor', primaryColor))
      ..add(ColorProperty('secondaryColor', secondaryColor))
      ..add(DiagnosticsProperty<Size>('editorBodySize', editorBodySize))
      ..add(IntProperty('startTime', _startTime))
      ..add(IntProperty('endTime', _endTime))
      ..add(IntProperty('duration', duration));
  }
}
