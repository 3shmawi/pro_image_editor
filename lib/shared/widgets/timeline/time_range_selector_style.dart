import 'package:flutter/material.dart';

/// Style configuration for the time range selector timeline.
///
/// This class defines the visual appearance of the timeline component,
/// including colors, sizes, borders, and other styling properties.
class TimeRangeSelectorStyle {
  /// Creates a [TimeRangeSelectorStyle] with customizable properties.
  const TimeRangeSelectorStyle({
    this.height = 60.0,
    this.handlerWidth = 8.0,
    this.handlerButtonSize = 16.0,
    this.handlerRadius = 8.0,
    this.borderWidth = 2.0,
    this.background = Colors.white,
    this.outsideAreaBackground = const Color(0x99000000),
    this.handlerColor = Colors.white,
    this.handlerIconColor = Colors.black,
    this.borderColor = Colors.white,
  });

  /// The height of the timeline bar.
  final double height;

  /// The width of the drag handlers.
  final double handlerWidth;

  /// The size of the handler button area (touch target).
  final double handlerButtonSize;

  /// The border radius of the timeline and handlers.
  final double handlerRadius;

  /// The width of the border around the selected area.
  final double borderWidth;

  /// The background color of the selected timeline area.
  final Color background;

  /// The background color of the area outside the selection.
  final Color outsideAreaBackground;

  /// The color of the drag handlers.
  final Color handlerColor;

  /// The color of the icons on the drag handlers.
  final Color handlerIconColor;

  /// The color of the border around the selected area.
  final Color borderColor;

  /// Creates a copy of this style with the given fields replaced.
  TimeRangeSelectorStyle copyWith({
    double? height,
    double? handlerWidth,
    double? handlerButtonSize,
    double? handlerRadius,
    double? borderWidth,
    Color? background,
    Color? outsideAreaBackground,
    Color? handlerColor,
    Color? handlerIconColor,
    Color? borderColor,
  }) {
    return TimeRangeSelectorStyle(
      height: height ?? this.height,
      handlerWidth: handlerWidth ?? this.handlerWidth,
      handlerButtonSize: handlerButtonSize ?? this.handlerButtonSize,
      handlerRadius: handlerRadius ?? this.handlerRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      background: background ?? this.background,
      outsideAreaBackground:
          outsideAreaBackground ?? this.outsideAreaBackground,
      handlerColor: handlerColor ?? this.handlerColor,
      handlerIconColor: handlerIconColor ?? this.handlerIconColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}
