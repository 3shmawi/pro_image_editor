import 'package:flutter/material.dart';

import '/core/models/layers/audio_layer.dart';
import '/shared/widgets/video/select_timmer_range/video_editor_select_range_thumbnails.dart';

/// A dialog for editing audio layer properties.
///
/// This dialog allows users to adjust the start time of an audio layer,
/// view its duration, and delete the layer if needed.
class AudioEditorDialog extends StatefulWidget {
  /// Creates an [AudioEditorDialog].
  const AudioEditorDialog({
    super.key,
    required this.audioLayer,
    required this.totalDuration,
    required this.theme,
    this.thumbnails,
  });

  /// The audio layer being edited.
  final AudioLayer audioLayer;

  /// The total duration of the video in milliseconds.
  final int totalDuration;

  /// The theme for styling the dialog.
  final ThemeData theme;

  /// Optional video thumbnails to display in the timeline.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  @override
  State<AudioEditorDialog> createState() => _AudioEditorDialogState();
}

class _AudioEditorDialogState extends State<AudioEditorDialog> {
  late int _startTime;
  late final int _duration;
  bool _markedForDeletion = false;

  @override
  void initState() {
    super.initState();
    _startTime = widget.audioLayer.startTime;
    _duration = widget.audioLayer.duration;
  }

  /// Gets the end time in milliseconds.
  int get _endTime => _startTime + _duration;

  /// Formats milliseconds to a readable time string (MM:SS.mmm).
  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final millis = duration.inMilliseconds.remainder(1000) ~/ 100;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis}';
  }

  /// Extracts filename from path.
  String _getFileName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }

  void _handleConfirm() {
    if (_markedForDeletion) {
      Navigator.of(context).pop('delete');
    } else {
      final updatedLayer = widget.audioLayer.copyWith(
        startTime: _startTime,
      );
      Navigator.of(context).pop(updatedLayer);
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _handleDelete() {
    setState(() {
      _markedForDeletion = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with icon
            Row(
              children: [
                Icon(
                  Icons.audiotrack,
                  color: widget.theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Audio Layer',
                        style: widget.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFileName(widget.audioLayer.path),
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_markedForDeletion)
              // Deletion confirmation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.theme.colorScheme.error,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: widget.theme.colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Delete this audio layer?',
                      style: widget.theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This action cannot be undone.',
                      style: widget.theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              // Normal editing view
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Audio info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Duration',
                          _formatTime(_duration),
                          Icons.timer,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Start Time',
                          _formatTime(_startTime),
                          Icons.play_arrow,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'End Time',
                          _formatTime(_endTime),
                          Icons.stop,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start time slider
                  Text(
                    'Adjust Start Time',
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Timeline visualization
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.theme.dividerColor,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Thumbnail background
                        if (widget.thumbnails != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: VideoEditorSelectRangeThumbnailBar(
                              thumbnails: widget.thumbnails,
                              height: 60,
                              borderRadius: 0,
                            ),
                          ),

                        // Audio layer bar
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final startPos = (_startTime / widget.totalDuration) *
                                constraints.maxWidth;
                            final width = (_duration / widget.totalDuration) *
                                constraints.maxWidth;
                            return Positioned(
                              left: startPos,
                              top: 10,
                              child: Container(
                                width: width.clamp(20.0, constraints.maxWidth),
                                height: 40,
                                decoration: BoxDecoration(
                                  color: widget.theme.colorScheme.primary
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: widget.theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.music_note,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slider
                  Slider(
                    value: _startTime.toDouble(),
                    min: 0,
                    max: (widget.totalDuration - _duration)
                        .toDouble()
                        .clamp(0, double.infinity),
                    divisions: ((widget.totalDuration - _duration) / 100)
                        .ceil()
                        .clamp(1, 1000),
                    label: _formatTime(_startTime),
                    onChanged: (value) {
                      setState(() {
                        _startTime = value.toInt();
                      });
                    },
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_markedForDeletion)
                  TextButton.icon(
                    onPressed: _handleDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      color: widget.theme.colorScheme.error,
                    ),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        color: widget.theme.colorScheme.error,
                      ),
                    ),
                  )
                else
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _markedForDeletion = false;
                      });
                    },
                    child: const Text('Cancel Delete'),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _handleCancel,
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: widget.theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _handleConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _markedForDeletion
                            ? widget.theme.colorScheme.error
                            : widget.theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(_markedForDeletion ? 'Confirm Delete' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: widget.theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: widget.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: widget.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

