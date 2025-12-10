import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../utils/debounce.dart';
import 'time_range_selector_config.dart';

/// A reusable widget for selecting a time range on a timeline.
///
/// This component provides a visual timeline with draggable handles to select
/// start and end times. It supports zooming, scrolling, and custom backgrounds.
class TimeRangeSelectorBar extends StatefulWidget {
  /// Creates a [TimeRangeSelectorBar] widget.
  const TimeRangeSelectorBar({
    super.key,
    required this.config,
    required this.backgroundWidget,
    this.overlayBuilder,
    this.onTimeRangeChanged,
    this.onTimeRangeChangeEnd,
    this.showPlayTimeIndicator = false,
    this.playTimeIndicator,
  });

  /// Configuration for the timeline behavior and constraints.
  final TimeRangeSelectorConfig config;

  /// The background widget to display (e.g., thumbnails, gradient).
  final Widget backgroundWidget;

  /// Optional builder for custom overlay content.
  /// Receives the context and the current trim width.
  final Widget Function(BuildContext context, double trimWidth)? overlayBuilder;

  /// Callback when the time range changes (during dragging).
  final void Function(int startMs, int endMs)? onTimeRangeChanged;

  /// Callback when the time range change ends (drag complete).
  final void Function(int startMs, int endMs)? onTimeRangeChangeEnd;

  /// Whether to show the play time indicator.
  final bool showPlayTimeIndicator;

  /// Custom play time indicator widget.
  final Widget? playTimeIndicator;

  @override
  State<TimeRangeSelectorBar> createState() => _TimeRangeSelectorBarState();
}

class _TimeRangeSelectorBarState extends State<TimeRangeSelectorBar> {
  late double _trimStart;
  late double _trimEnd;
  double _scale = 1.0;
  double _baseScale = 1.0;
  final _scrollCtrl = ScrollController();
  final _trimTimeDebounce = Debounce(const Duration(milliseconds: 350));

  bool _isUpdatingTrimBar = false;

  final _leftHandlerActiveNotifier = ValueNotifier(false);
  final _rightHandlerActiveNotifier = ValueNotifier(false);

  double get _minTrimPercentage =>
      widget.config.minDuration / widget.config.totalDuration;

  double get _maxTrimPercentage {
    final maxDurationMs = widget.config.maxDuration;
    return min(maxDurationMs / widget.config.totalDuration, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _trimStart = widget.config.startTime / widget.config.totalDuration;
    _trimEnd = widget.config.endTime / widget.config.totalDuration;
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _trimTimeDebounce.dispose();
    _leftHandlerActiveNotifier.dispose();
    _rightHandlerActiveNotifier.dispose();
    super.dispose();
  }

  void _updateTrimSpan() {
    final startMs = (_trimStart * widget.config.totalDuration).round();
    final endMs = (_trimEnd * widget.config.totalDuration).round();

    widget.onTimeRangeChanged?.call(startMs, endMs);
    _isUpdatingTrimBar = true;
    setState(() {});
  }

  void _updateTrimStart(double value) {
    _trimStart = value.clamp(
      _trimEnd - _maxTrimPercentage,
      _trimEnd - _minTrimPercentage,
    );
    _updateTrimSpan();
  }

  void _updateTrimEnd(double value) {
    _trimEnd = value.clamp(
      _trimStart + _minTrimPercentage,
      _trimStart + _maxTrimPercentage,
    );
    _updateTrimSpan();
  }

  void _updateDragTrimBar(DragUpdateDetails details, double scaledWidth) {
    double factor = details.primaryDelta! / scaledWidth;

    double newValueStart = _trimStart + factor;
    double newValueEnd = _trimEnd + factor;
    double diff = _trimEnd - _trimStart;

    if (newValueStart < 0) {
      newValueStart = 0;
      newValueEnd = diff;
    } else if (newValueEnd > 1) {
      newValueStart = 1 - diff;
      newValueEnd = 1;
    }

    _trimStart = newValueStart;
    _trimEnd = newValueEnd;

    _updateTrimSpan();
  }

  void _triggerTrimSpanEnd() {
    final startMs = (_trimStart * widget.config.totalDuration).toInt();
    final endMs = (_trimEnd * widget.config.totalDuration).toInt();

    widget.onTimeRangeChangeEnd?.call(startMs, endMs);
    _isUpdatingTrimBar = false;
    _trimTimeDebounce(() {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _handleMouseScroll(PointerSignalEvent event, double trimBarWidth) {
    if (event is! PointerScrollEvent) return;

    // Define zoom factor dynamically based on scroll speed
    double factor = 0.05 * (event.scrollDelta.dy / 50).abs().clamp(0.5, 2);

    double deltaY =
        event.scrollDelta.dy * (widget.config.invertMouseScroll ? -1 : 1);

    double startZoom = _scale;
    double newZoom = _scale;

    // Adjust zoom based on scroll direction
    if (deltaY > 0) {
      newZoom -= factor;
      newZoom = max(widget.config.minScale, newZoom);
    } else if (deltaY < 0) {
      newZoom += factor;
      newZoom = min(widget.config.maxScale, newZoom);
    }

    /// Get the local mouse position relative to the trim bar
    double mouseX = event.localPosition.dx;

    /// Get the total scrollable width
    double scaledWidth = trimBarWidth * startZoom;
    double newScaledWidth = trimBarWidth * newZoom;

    /// Convert mouse position to percentage in the current zoom level
    double mousePositionPercent = (mouseX + _scrollCtrl.offset) / scaledWidth;

    /// Compute the new scroll offset so that zooming happens around
    /// the mouse pointer
    double newScrollOffset = (mousePositionPercent * newScaledWidth) - mouseX;

    /// Ensure new scroll offset is within valid range
    double clampedScrollOffset = max(
      0,
      min(_scrollCtrl.position.maxScrollExtent, newScrollOffset),
    );

    setState(() {
      _scale = newZoom;
    });

    // Apply the new scroll position
    _scrollCtrl.jumpTo(clampedScrollOffset);
  }

  @override
  Widget build(BuildContext context) {
    var style = widget.config.style;
    var handlerButtonSize = style.handlerButtonSize;

    return RepaintBoundary(
      child: LayoutBuilder(builder: (_, constraints) {
        double trimBarWidth = constraints.maxWidth - 16;
        double scaledWidth = trimBarWidth * _scale;
        double trimWidth = (_trimEnd - _trimStart) * scaledWidth;
        double offsetLeftHandler = _trimStart * scaledWidth;
        double offsetRightHandler = _trimEnd * scaledWidth - style.handlerWidth;

        /// Ensure there is always a small gap between the handlers
        if (offsetLeftHandler + style.handlerWidth + 4 >= offsetRightHandler) {
          offsetRightHandler = offsetLeftHandler + 4;
        }

        return SingleChildScrollView(
          controller: _scrollCtrl,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Listener(
            onPointerSignal: (ev) => _handleMouseScroll(ev, trimBarWidth),
            child: GestureDetector(
              onScaleStart: (ScaleStartDetails details) {
                _baseScale = _scale;
              },
              onScaleUpdate: (ScaleUpdateDetails details) {
                _scale = (_baseScale * details.scale).clamp(
                  widget.config.minScale,
                  widget.config.maxScale,
                );
                setState(() {});
              },
              child: Container(
                clipBehavior: Clip.none,
                width: scaledWidth,
                padding: const EdgeInsets.only(top: 8.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    /// Background widget (thumbnails, gradient, etc.)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: handlerButtonSize,
                      ),
                      child: widget.backgroundWidget,
                    ),

                    /// Outside shadows
                    ..._buildOutsideShadows(
                      offsetLeftHandler,
                      offsetRightHandler,
                      scaledWidth,
                    ),

                    /// Trim body area
                    _buildTrimBodyArea(
                      offsetLeftHandler + handlerButtonSize,
                      offsetRightHandler - handlerButtonSize,
                      scaledWidth,
                      trimWidth,
                    ),

                    /// Trim handler left
                    _buildResizeHandler(true, offsetLeftHandler, scaledWidth),

                    /// Trim handler right
                    _buildResizeHandler(false, offsetRightHandler, scaledWidth),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  List<Widget> _buildOutsideShadows(
    double offsetLeftHandler,
    double offsetRightHandler,
    double scaledWidth,
  ) {
    var style = widget.config.style;
    double radiusWidth = style.handlerRadius;
    var handlerButtonSize = style.handlerButtonSize;
    return [
      Positioned(
        left: handlerButtonSize,
        width: offsetLeftHandler + radiusWidth,
        height: style.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: style.outsideAreaBackground,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(style.handlerRadius),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        left: offsetRightHandler + handlerButtonSize,
        width: scaledWidth - offsetRightHandler - handlerButtonSize * 2,
        height: style.height,
        child: IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: style.outsideAreaBackground,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(style.handlerRadius),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildTrimBodyArea(
    double offsetLeftHandler,
    double offsetRightHandler,
    double scaledWidth,
    double trimWidth,
  ) {
    var style = widget.config.style;

    return Positioned(
      left: offsetLeftHandler,
      width: offsetRightHandler - offsetLeftHandler + style.handlerWidth,
      child: Stack(
        children: [
          /// Custom overlay (if provided)
          if (widget.overlayBuilder != null)
            widget.overlayBuilder!(context, trimWidth),

          /// Play-time indicator
          if (widget.showPlayTimeIndicator &&
              !_isUpdatingTrimBar &&
              widget.playTimeIndicator != null)
            widget.playTimeIndicator!,

          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (_) => _triggerTrimSpanEnd(),
            onHorizontalDragUpdate: (details) =>
                _updateDragTrimBar(details, scaledWidth),
            child: MouseRegion(
              cursor: SystemMouseCursors.move,
              child: Container(
                width: trimWidth,
                height: style.height,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: style.borderColor,
                    width: style.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    style.handlerRadius,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandler(bool isLeft, double offset, double scaledWidth) {
    var notifier =
        isLeft ? _leftHandlerActiveNotifier : _rightHandlerActiveNotifier;
    var style = widget.config.style;

    return Positioned(
      left: offset,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragStart: (_) {
          notifier.value = true;
        },
        onHorizontalDragUpdate: (details) {
          if (isLeft) {
            double newValue = _trimStart + details.primaryDelta! / scaledWidth;
            _updateTrimStart(max(0, newValue));
          } else {
            double newValue = _trimEnd + details.primaryDelta! / scaledWidth;
            _updateTrimEnd(min(1, newValue));
          }
        },
        onHorizontalDragEnd: (_) {
          _triggerTrimSpanEnd();
          notifier.value = false;
        },
        child: ValueListenableBuilder(
          valueListenable: notifier,
          builder: (_, isSelected, __) {
            return _buildHandle(isLeft, isSelected, style);
          },
        ),
      ),
    );
  }

  Widget _buildHandle(bool isLeft, bool isSelected, style) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: Container(
        height: style.height,
        width: style.handlerButtonSize,
        alignment: Alignment.center,
        child: Container(
          width: style.handlerWidth,
          height: style.height,
          decoration: BoxDecoration(
            color: style.handlerColor,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? Radius.circular(style.handlerRadius) : Radius.zero,
              right:
                  !isLeft ? Radius.circular(style.handlerRadius) : Radius.zero,
            ),
            border: Border.all(
              color: isSelected ? style.borderColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              isLeft ? Icons.chevron_left : Icons.chevron_right,
              color: style.handlerIconColor,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }
}
