# LayersTimelineBar Usage Example

## Basic Integration

Here's a complete example showing how to integrate the `LayersTimelineBar` into your video editor:

```dart
import 'package:flutter/material.dart';
import 'package:pro_image_editor/core/models/layers/audio_layer.dart';
import 'package:pro_image_editor/core/models/layers/video_bubble_layer.dart';
import 'package:pro_image_editor/core/models/timed_layers/timed_text_layer.dart';
import 'package:pro_image_editor/core/models/timed_layers/timed_paint_layer.dart';
import 'package:pro_image_editor/features/audio_editor/widgets/audio_timeline_bar.dart'
    show LayersTimelineBar;

class VideoEditorWithTimeline extends StatefulWidget {
  @override
  State<VideoEditorWithTimeline> createState() => _VideoEditorWithTimelineState();
}

class _VideoEditorWithTimelineState extends State<VideoEditorWithTimeline> {
  // Current playback position
  final ValueNotifier<Duration> _currentTimeNotifier = ValueNotifier(Duration.zero);
  
  // Video thumbnails for timeline background
  final ValueNotifier<List<ImageProvider>?> _thumbnailsNotifier = ValueNotifier(null);
  
  // Total video duration in milliseconds
  int _totalDuration = 30000; // 30 seconds
  
  // Layer lists
  List<AudioLayer> _audioLayers = [];
  List<TimedTextLayer> _timedTextLayers = [];
  List<TimedPaintLayer> _timedPaintLayers = [];
  List<VideoBubbleLayer> _videoBubbleLayers = [];

  @override
  void initState() {
    super.initState();
    _loadLayers();
  }

  void _loadLayers() {
    // Example: Load layers from your data source
    _audioLayers = [
      AudioLayer(
        path: '/path/to/audio1.mp3',
        duration: 5000, // 5 seconds
        startTime: 2000, // starts at 2 seconds
      ),
      AudioLayer(
        path: '/path/to/audio2.mp3',
        duration: 3000,
        startTime: 10000,
      ),
    ];

    _timedTextLayers = [
      TimedTextLayer(
        text: 'Hello World!',
        startTime: 0,
        endTime: 5000,
        color: Colors.white,
        background: Colors.black,
      ),
      TimedTextLayer(
        text: 'Welcome to the video',
        startTime: 5000,
        endTime: 10000,
        color: Colors.blue,
        background: Colors.white,
      ),
    ];

    _timedPaintLayers = [
      TimedPaintLayer(
        item: myPaintedModel,
        rawSize: Size(200, 200),
        opacity: 1.0,
        startTime: 3000,
        endTime: 8000,
      ),
    ];

    _videoBubbleLayers = [
      VideoBubbleLayer(
        path: '/path/to/bubble.mp4',
        duration: 5000,
        startTime: 15000,
      ),
    ];

    setState(() {});
  }

  void _handleLayerTap(Layer layer) {
    if (layer is AudioLayer) {
      // Open audio editor dialog with preview
      showDialog(
        context: context,
        builder: (context) => AudioEditorDialog(
          audioLayer: layer,
          totalDuration: _totalDuration,
          theme: Theme.of(context),
        ),
      );
    } else if (layer is VideoBubbleLayer) {
      // Open video bubble editor dialog (similar to audio)
      // Seek to start time and show preview
    } else if (layer is TimedTextLayer) {
      // Seek to the layer's start time
      _currentTimeNotifier.value = Duration(milliseconds: layer.startTime);
      // Optionally open text editor
    } else if (layer is TimedPaintLayer) {
      // Seek to the layer's start time
      _currentTimeNotifier.value = Duration(milliseconds: layer.startTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Editor with Timeline'),
      ),
      body: Column(
        children: [
          // Your video player or editor content here
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Text(
                  'Video Editor Content',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          
          // Timeline bar at the bottom
          LayersTimelineBar(
            audioLayers: _audioLayers,
            timedTextLayers: _timedTextLayers,
            timedPaintLayers: _timedPaintLayers,
            videoBubbleLayers: _videoBubbleLayers,
            totalDuration: _totalDuration,
            currentTimeNotifier: _currentTimeNotifier,
            onLayerTap: _handleLayerTap,
            theme: Theme.of(context),
            thumbnails: _thumbnailsNotifier,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentTimeNotifier.dispose();
    _thumbnailsNotifier.dispose();
    super.dispose();
  }
}
```

## Updating Current Time

To sync the timeline with video playback:

```dart
// In your video player controller callback
void _onVideoPositionChanged(Duration position) {
  _currentTimeNotifier.value = position;
}
```

## Loading Thumbnails

To display video thumbnails in the timeline:

```dart
Future<void> _loadThumbnails(String videoPath) async {
  final thumbnails = await generateVideoThumbnails(
    videoPath: videoPath,
    count: 10, // Number of thumbnails to generate
  );
  
  _thumbnailsNotifier.value = thumbnails.map(
    (bytes) => MemoryImage(bytes)
  ).toList();
}
```

## Adding Layers Dynamically

```dart
void _addAudioLayer(String audioPath, int duration) {
  setState(() {
    _audioLayers.add(
      AudioLayer(
        path: audioPath,
        duration: duration,
        startTime: _currentTimeNotifier.value.inMilliseconds,
      ),
    );
  });
}

void _addTimedText(String text, int duration) {
  setState(() {
    final startTime = _currentTimeNotifier.value.inMilliseconds;
    _timedTextLayers.add(
      TimedTextLayer(
        text: text,
        startTime: startTime,
        endTime: startTime + duration,
        color: Colors.white,
        background: Colors.black,
      ),
    );
  });
}
```

## Removing Layers

```dart
void _removeAudioLayer(AudioLayer layer) {
  setState(() {
    _audioLayers.remove(layer);
  });
}

void _removeAllLayers() {
  setState(() {
    _audioLayers.clear();
    _timedTextLayers.clear();
    _timedPaintLayers.clear();
    _videoBubbleLayers.clear();
  });
}
```

## Filtering Layers by Time

```dart
List<AudioLayer> getActiveAudioLayers(int currentTimeMs) {
  return _audioLayers.where((layer) {
    return layer.isPlayingAtTime(currentTimeMs);
  }).toList();
}

List<TimedTextLayer> getActiveTextLayers(int currentTimeMs) {
  return _timedTextLayers.where((layer) {
    return layer.isVisibleAtTime(currentTimeMs);
  }).toList();
}
```

## Complete Example with Layer Management

```dart
class AdvancedVideoEditor extends StatefulWidget {
  @override
  State<AdvancedVideoEditor> createState() => _AdvancedVideoEditorState();
}

class _AdvancedVideoEditorState extends State<AdvancedVideoEditor> {
  final ValueNotifier<Duration> _currentTimeNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<List<ImageProvider>?> _thumbnailsNotifier = ValueNotifier(null);
  
  int _totalDuration = 30000;
  List<AudioLayer> _audioLayers = [];
  List<TimedTextLayer> _timedTextLayers = [];
  List<TimedPaintLayer> _timedPaintLayers = [];
  List<VideoBubbleLayer> _videoBubbleLayers = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Video preview
          Expanded(
            child: Stack(
              children: [
                // Video player
                VideoPlayer(),
                
                // Active timed text overlays
                ...getActiveTextLayers(_currentTimeNotifier.value.inMilliseconds)
                    .map((layer) => TimedTextOverlay(layer: layer)),
                
                // Active paint overlays
                ...getActivePaintLayers(_currentTimeNotifier.value.inMilliseconds)
                    .map((layer) => TimedPaintOverlay(layer: layer)),
              ],
            ),
          ),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.audiotrack),
                onPressed: _addAudioDialog,
              ),
              IconButton(
                icon: Icon(Icons.text_fields),
                onPressed: _addTextDialog,
              ),
              IconButton(
                icon: Icon(Icons.brush),
                onPressed: _addPaintDialog,
              ),
              IconButton(
                icon: Icon(Icons.video_library),
                onPressed: _addVideoBubbleDialog,
              ),
            ],
          ),
          
          // Timeline
          AudioTimelineBar(
            audioLayers: _audioLayers,
            timedTextLayers: _timedTextLayers,
            timedPaintLayers: _timedPaintLayers,
            videoBubbleLayers: _videoBubbleLayers,
            totalDuration: _totalDuration,
            currentTimeNotifier: _currentTimeNotifier,
            onAudioLayerTap: _editAudioLayer,
            theme: Theme.of(context),
            thumbnails: _thumbnailsNotifier,
          ),
        ],
      ),
    );
  }

  void _addAudioDialog() {
    // Show dialog to add audio layer
  }

  void _addTextDialog() {
    // Show dialog to add text layer
  }

  void _addPaintDialog() {
    // Show dialog to add paint layer
  }

  void _addVideoBubbleDialog() {
    // Show dialog to add video bubble layer
  }

  void _editAudioLayer(AudioLayer layer) {
    // Open audio editor for the layer
  }

  List<TimedTextLayer> getActiveTextLayers(int currentTimeMs) {
    return _timedTextLayers.where((layer) {
      return layer.isVisibleAtTime(currentTimeMs);
    }).toList();
  }

  List<TimedPaintLayer> getActivePaintLayers(int currentTimeMs) {
    return _timedPaintLayers.where((layer) {
      return layer.isVisibleAtTime(currentTimeMs);
    }).toList();
  }
}
```

## Tips and Best Practices

1. **Performance**: For videos with many layers, consider virtualizing the timeline or limiting the number of visible layer bars.

2. **User Feedback**: Provide visual feedback when tapping on layer bars (e.g., highlighting, ripple effect).

3. **Accessibility**: Ensure the timeline is accessible with proper semantic labels and touch targets.

4. **Responsive Design**: The timeline adapts to screen width, but consider different layouts for tablets vs. phones.

5. **State Management**: Use a state management solution (Provider, Riverpod, Bloc) for complex layer management.

6. **Undo/Redo**: Implement undo/redo functionality for layer additions and modifications.

7. **Validation**: Validate layer timings to prevent overlaps or invalid time ranges.

