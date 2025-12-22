import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/video_bubble_layer.dart';
import '/features/main_editor/services/ffmpeg_export_service.dart';

/// A widget for picking or recording a video bubble.
class VideoBubblePickerWidget extends StatefulWidget {
  /// Creates a new video bubble picker widget.
  const VideoBubblePickerWidget({
    super.key,
    required this.configs,
    required this.onVideoPicked,
    this.videoLayers,
    this.onDeleteLayer,
    this.preloadedVideoPath,
  });

  /// The editor configurations.
  final ProImageEditorConfigs configs;

  /// Callback when a video is picked.
  final Function(
    String path,
    int duration,
    VideoBubbleCorner corner,
    double scale,
  ) onVideoPicked;

  /// List of existing video bubble layers.
  final List<VideoBubbleLayer>? videoLayers;

  /// Callback when a video bubble layer is deleted.
  final Function(VideoBubbleLayer layer)? onDeleteLayer;

  /// Optional preloaded video path (e.g., from camera recording).
  /// When provided, the widget will automatically load this video.
  final String? preloadedVideoPath;

  @override
  State<VideoBubblePickerWidget> createState() =>
      _VideoBubblePickerWidgetState();
}

class _VideoBubblePickerWidgetState extends State<VideoBubblePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  VideoPlayerController? _videoController;
  VideoPlayerController? _previewController;
  String? _videoPath;
  String? _previewPath;
  VideoBubbleCorner _selectedCorner = VideoBubbleCorner.bottomRight;
  double _bubbleScale = 0.15;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // If a preloaded video path is provided (e.g., from camera),
    // automatically load it
    if (widget.preloadedVideoPath != null) {
      _loadPreloadedVideo();
    }
  }

  Future<void> _loadPreloadedVideo() async {
    setState(() => _isLoading = true);

    try {
      _videoPath = widget.preloadedVideoPath;

      _videoController = VideoPlayerController.file(
        File(_videoPath!),
      );

      await _videoController!.initialize();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading video: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    // For camera source, we need to handle the activity switch differently
    // to prevent the bottom sheet from losing state
    if (source == ImageSource.camera) {
      await _pickVideoFromCamera();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final XFile? video = await _picker.pickVideo(source: source);

      if (video != null) {
        _videoPath = video.path;

        // Initialize video player to get duration
        _videoController = VideoPlayerController.file(
          File(_videoPath!),
        );

        await _videoController!.initialize();

        setState(() => _isLoading = false);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  /// Picks video from camera by first closing the bottom sheet,
  /// then opening the camera, to avoid state loss on some devices.
  Future<void> _pickVideoFromCamera() async {
    // Pop the bottom sheet and return a special marker to indicate camera mode
    Navigator.of(context).pop({'action': 'camera'});
  }

  Future<void> _playPreview(String path) async {
    if (_previewPath == path) {
      if (_previewController != null) {
        if (_previewController!.value.isPlaying) {
          await _previewController!.pause();
        } else {
          await _previewController!.play();
        }
        setState(() {});
      }
    } else {
      _previewController?.dispose();
      _previewController = VideoPlayerController.file(File(path));
      await _previewController!.initialize();
      await _previewController!.play();
      _previewController!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() {
        _previewPath = path;
      });
    }
  }

  void _confirmSelection() {
    if (_videoPath != null && _videoController != null) {
      final duration = _videoController!.value.duration.inMilliseconds;
      widget.onVideoPicked(
        _videoPath!,
        duration,
        _selectedCorner,
        _bubbleScale,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add Video Bubble',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (widget.videoLayers != null && widget.videoLayers!.isNotEmpty) ...[
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.videoLayers!.length,
                itemBuilder: (context, index) {
                  final layer = widget.videoLayers![index];
                  final isPreviewing = _previewPath == layer.path;
                  return ListTile(
                    leading: isPreviewing &&
                            _previewController != null &&
                            _previewController!.value.isInitialized
                        ? ClipOval(
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _previewController!.value.size.width,
                                  height: _previewController!.value.size.height,
                                  child: VideoPlayer(_previewController!),
                                ),
                              ),
                            ),
                          )
                        : const Icon(Icons.videocam, color: Colors.white),
                    title: Text(
                      'Bubble ${index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${_formatDuration(Duration(milliseconds: layer.startTime))} - '
                      '${_formatDuration(Duration(milliseconds: layer.endTime))}\n'
                      '${layer.corner.name}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isPreviewing &&
                                    _previewController != null &&
                                    _previewController!.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () => _playPreview(layer.path),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            widget.onDeleteLayer?.call(layer);
                            setState(() {
                              widget.videoLayers?.remove(layer);
                              if (_previewPath == layer.path) {
                                _previewController?.dispose();
                                _previewController = null;
                                _previewPath = null;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 10),
          ],
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_videoPath == null) ...[
            // Video source selection
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  icon: Icons.video_library,
                  label: 'Gallery',
                  onTap: () => _pickVideo(ImageSource.gallery),
                ),
                _buildSourceButton(
                  icon: Icons.videocam,
                  label: 'Camera',
                  onTap: () => _pickVideo(ImageSource.camera),
                ),
              ],
            ),
          ] else ...[
            // Video preview (circular bubble preview)
            if (_videoController != null &&
                _videoController!.value.isInitialized)
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Duration display
            Text(
              'Duration: ${_formatDuration(_videoController!.value.duration)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            // Corner selection
            const Text(
              'Position',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildCornerSelector(),
            const SizedBox(height: 20),

            // Scale slider
            const Text(
              'Size',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Small',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Expanded(
                  child: Slider(
                    value: _bubbleScale,
                    min: 0.15,
                    max: 0.5,
                    divisions: 7,
                    label: '${(_bubbleScale * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() => _bubbleScale = value);
                    },
                  ),
                ),
                const Text(
                  'Large',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _videoPath = null;
                      _videoController?.dispose();
                      _videoController = null;
                    });
                  },
                  child: const Text(
                    'Change Video',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Add Bubble',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCornerOption(VideoBubbleCorner.topLeft, 'Top Left'),
              _buildCornerOption(VideoBubbleCorner.topRight, 'Top Right'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCornerOption(VideoBubbleCorner.bottomLeft, 'Bottom Left'),
              _buildCornerOption(
                VideoBubbleCorner.bottomRight,
                'Bottom Right',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCornerOption(VideoBubbleCorner corner, String label) {
    final isSelected = _selectedCorner == corner;
    return InkWell(
      onTap: () => setState(() => _selectedCorner = corner),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.white30,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
