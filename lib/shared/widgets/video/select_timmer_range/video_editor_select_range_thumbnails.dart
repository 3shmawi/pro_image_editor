import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '/shared/widgets/video/video_editor_configurable.dart';

/// Displays a thumbnail preview of the video trim selection.
///
/// This widget shows a series of generated thumbnails representing
/// different frames of the trimmed video section.
///
/// Can be used standalone with provided parameters or within a
/// [VideoEditorConfigurable] context.
class VideoEditorSelectRangeThumbnailBar extends StatelessWidget {
  /// Creates a [VideoEditorSelectRangeThumbnailBar] widget.
  const VideoEditorSelectRangeThumbnailBar({
    super.key,
    this.thumbnails,
    this.height,
    this.gradient,
    this.borderRadius,
    this.skeletonLoader,
  });

  /// Optional list of thumbnails to display.
  /// If null, will attempt to use [VideoEditorConfigurable] context.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  /// Optional height for the thumbnail bar.
  /// If null, will use the style from [VideoEditorConfigurable].
  final double? height;

  /// Optional gradient background.
  /// If null, will use the style from [VideoEditorConfigurable].
  final Gradient? gradient;

  /// Optional border radius.
  /// If null, will use the style from [VideoEditorConfigurable].
  final double? borderRadius;

  /// Optional custom skeleton loader widget.
  final Widget? skeletonLoader;

  @override
  Widget build(BuildContext context) {
    // Try to get video editor config if available
    var player = VideoEditorConfigurable.maybeOf(context);

    // Use provided values or fallback to player config
    final effectiveThumbnails =
        thumbnails ?? player?.controller.thumbnailsNotifier;
    final effectiveHeight = height ?? player?.style.trimBarHeight ?? 60.0;
    final effectiveGradient =
        gradient ?? player?.style.trimBarGradientBackground;
    final effectiveBorderRadius =
        borderRadius ?? player?.style.trimBarHandlerRadius ?? 8.0;

    // Use provided skeleton loader, or player's skeleton loader, or a simple fallback
    final effectiveSkeletonLoader = skeletonLoader ??
        player?.widgets.trimBarSkeletonLoader ??
        _buildSimpleSkeleton(effectiveHeight, effectiveBorderRadius);

    // If no thumbnails notifier available, show skeleton
    if (effectiveThumbnails == null) {
      return Container(
        clipBehavior: Clip.hardEdge,
        height: effectiveHeight,
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(effectiveBorderRadius),
        ),
        child: effectiveSkeletonLoader,
      );
    }

    return Container(
      clipBehavior: Clip.hardEdge,
      height: effectiveHeight,
      decoration: BoxDecoration(
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(effectiveBorderRadius),
      ),
      child: ValueListenableBuilder(
        valueListenable: effectiveThumbnails,
        builder: (_, thumbnailList, __) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: thumbnailList == null
                ? effectiveSkeletonLoader
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: thumbnailList.map((item) {
                      return Expanded(
                        child: Image(
                          image: item,
                          fit: BoxFit.cover,
                        ),
                      );
                    }).toList(),
                  ),
          );
        },
      ),
    );
  }

  /// Builds a simple skeleton loader that doesn't require VideoEditorConfigurable.
  Widget _buildSimpleSkeleton(double height, double borderRadius) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          Icons.video_library,
          color: Colors.grey[400],
          size: 32,
        ),
      ),
    );
  }
}
