import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '/core/models/layers/video_bubble_layer.dart';
import '/shared/widgets/video/select_timmer_range/video_editor_select_range_thumbnails.dart';

/// A dialog for editing video bubble layer properties.
///
/// This dialog allows users to adjust the start time of a video bubble layer,
/// view its duration, preview the video, and delete the layer if needed.
class VideoBubbleEditorDialog extends StatefulWidget {
  /// Creates a [VideoBubbleEditorDialog].
  const VideoBubbleEditorDialog({
    super.key,
    required this.videoBubbleLayer,
    required this.totalDuration,
    required this.theme,
    this.thumbnails,
  });

  /// The video bubble layer being edited.
  final VideoBubbleLayer videoBubbleLayer;

  /// The total duration of the main video in milliseconds.
  final int totalDuration;

  /// The theme for styling the dialog.
  final ThemeData theme;

  /// Optional video thumbnails to display in the timeline.
  final ValueNotifier<List<ImageProvider>?>? thumbnails;

  @override
  State<VideoBubbleEditorDialog> createState() => _VideoBubbleEditorDialogState();
}

class _VideoBubbleEditorDialogState extends State<VideoBubbleEditorDialog> {
  late int _startTime;
  late final int _duration;
  bool _markedForDeletion = false;
  
  // Video player for preview
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _duration = widget.videoBubbleLayer.duration;
    // Clamp start time to ensure it's within valid range
    final maxStartTime = (widget.totalDuration - _duration).clamp(0, widget.totalDuration);
    _startTime = widget.videoBubbleLayer.startTime.clamp(0, maxStartTime);
    _toggleVideoPreview();
  }

  @override
  void dispose() {
    _disposeVideoPlayer();
    super.dispose();
  }

  /// Disposes the video player.
  Future<void> _disposeVideoPlayer() async {
    await _videoController?.pause();
    await _videoController?.dispose();
    _videoController = null;
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
      final updatedLayer = widget.videoBubbleLayer.copyWith(
        startTime: _startTime,
      );
      Navigator.of(context).pop(updatedLayer);
    }
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _handleDelete() {
    _disposeVideoPlayer();
    setState(() {
      _markedForDeletion = true;
    });
  }

  /// Toggles video playback preview.
  Future<void> _toggleVideoPreview() async {
    if (_videoController != null) {
      // If already initialized, just toggle play/pause
      if (_isPlaying) {
        await _videoController!.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } else {
      // Initialize video player
      setState(() {
        _isLoading = true;
      });
      
      try {
        _videoController = VideoPlayerController.file(
          File(widget.videoBubbleLayer.path),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
          ),
        );
        
        await _videoController!.initialize();
        
        // Add listener for play/pause state
        _videoController!.addListener(() {
          if (mounted && _videoController != null) {
            final isPlaying = _videoController!.value.isPlaying;
            if (_isPlaying != isPlaying) {
              setState(() {
                _isPlaying = isPlaying;
              });
            }
          }
        });
        
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        
        // Start playing
        await _videoController!.play();
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading video: $e')),
          );
        }
      }
    }
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
                  Icons.video_library,
                  color: widget.theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Video Bubble Layer',
                        style: widget.theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFileName(widget.videoBubbleLayer.path),
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
                      'Delete this video bubble layer?',
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
                  
                  // Video info card with preview button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: widget.theme.colorScheme.primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (_isInitialized && _videoController != null)
                        ListTile(
                          title: SizedBox(
                            height: 80,
                            width: 80,
                            child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                          ),
                      trailing: IconButton(
                        onPressed: _toggleVideoPreview,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                        ),
                        const SizedBox(height: 16),
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

                        // Video bubble layer bar
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
                                  color: Colors.purple
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.purple,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.video_library,
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
                  if ((widget.totalDuration - _duration) > 0)
                    Slider(
                      value: _startTime.toDouble(),
                      min: 0,
                      max: (widget.totalDuration - _duration).toDouble(),
                      divisions: ((widget.totalDuration - _duration) / 100)
                          .ceil()
                          .clamp(1, 1000),
                      label: _formatTime(_startTime),
                      onChanged: (value) {
                        setState(() {
                          _startTime = value.toInt();
                        });
                      },
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Video bubble duration is equal to or exceeds the main video duration. Start time cannot be adjusted.',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_markedForDeletion)
                  IconButton(
                    onPressed: _handleDelete,
                    icon: const Icon(Icons.delete_outline),
                    color: widget.theme.colorScheme.error,
                  )
               ,
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

