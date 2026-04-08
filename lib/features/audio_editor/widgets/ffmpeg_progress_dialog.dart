import 'package:flutter/material.dart';

/// A dialog that displays FFmpeg encoding progress.
///
/// This dialog shows a progress bar, percentage, and status message
/// during the FFmpeg audio merging process.
class FfmpegProgressDialog extends StatelessWidget {
  /// Creates an [FfmpegProgressDialog].
  const FfmpegProgressDialog({
    super.key,
    required this.progress,
    required this.theme,
    this.message,
  });

  /// The current progress value (0.0 to 1.0).
  final double progress;

  /// The theme for styling the dialog.
  final ThemeData theme;

  /// Optional status message to display.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).clamp(0, 100).toInt();

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.video_library,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Exporting Video',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              message ?? 'Merging audio layers with video...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Progress bar
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Percentage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (progress > 0 && progress < 1)
                  Text(
                    'Please wait...',
                    style: theme.textTheme.bodySmall,
                  )
                else if (progress >= 1)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Complete',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // Processing indicator
            if (progress > 0 && progress < 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A stateful wrapper for the FFmpeg progress dialog that can be updated.
class FfmpegProgressDialogController extends StatefulWidget {
  /// Creates an [FfmpegProgressDialogController].
  const FfmpegProgressDialogController({
    super.key,
    required this.progressNotifier,
    required this.theme,
    this.messageNotifier,
  });

  /// Notifier for progress updates (0.0 to 1.0).
  final ValueNotifier<double> progressNotifier;

  /// Notifier for message updates.
  final ValueNotifier<String?>? messageNotifier;

  /// The theme for styling the dialog.
  final ThemeData theme;

  @override
  State<FfmpegProgressDialogController> createState() =>
      _FfmpegProgressDialogControllerState();
}

class _FfmpegProgressDialogControllerState
    extends State<FfmpegProgressDialogController> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.progressNotifier,
      builder: (context, progress, _) {
        return ValueListenableBuilder<String?>(
          valueListenable:
              widget.messageNotifier ?? ValueNotifier<String?>(null),
          builder: (context, message, _) {
            return FfmpegProgressDialog(
              progress: progress,
              theme: widget.theme,
              message: message,
            );
          },
        );
      },
    );
  }
}
