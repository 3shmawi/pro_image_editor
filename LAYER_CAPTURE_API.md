# Layer Capture API Documentation

## Overview

The Pro Image Editor now includes powerful APIs for capturing layers individually or at specific time points. This is essential for video editing workflows where you need to render each layer separately or capture frames at different timestamps.

## New Methods

### 1. `captureEditorImageWithLayers()`

Captures the editor image with only specific layers visible.

```dart
Future<Uint8List> captureEditorImageWithLayers({
  List<String> visibleLayerIds = const [],
})
```

**Parameters:**
- `visibleLayerIds` - List of layer IDs to keep visible. If empty, captures only the background.

**Returns:** `Uint8List` containing the image with only specified layers.

**Example:**
```dart
// Capture only the first layer
final layerImage = await editorState.captureEditorImageWithLayers(
  visibleLayerIds: [activeLayers[0].id],
);

// Capture background only (no layers)
final backgroundImage = await editorState.captureEditorImageWithLayers(
  visibleLayerIds: [],
);

// Capture multiple specific layers
final multiLayerImage = await editorState.captureEditorImageWithLayers(
  visibleLayerIds: ['layer-1-id', 'layer-2-id'],
);
```

---

### 2. `captureLayersIndividually()`

Captures each layer individually and returns a map of layer ID to image.

```dart
Future<Map<String, Uint8List>> captureLayersIndividually({
  bool includeBackground = true,
})
```

**Parameters:**
- `includeBackground` - Whether to include a 'background' entry with just the background image (no layers).

**Returns:** `Map<String, Uint8List>` where keys are layer IDs (or 'background') and values are image bytes.

**Example:**
```dart
final layerImages = await editorState.captureLayersIndividually();

// layerImages contains:
// {
//   'background': Uint8List(...),      // Background only
//   'layer-id-1': Uint8List(...),      // First layer
//   'layer-id-2': Uint8List(...),      // Second layer
//   ...
// }

// Use in video rendering
for (var entry in layerImages.entries) {
  if (entry.key == 'background') {
    // Set as base video frame
    await videoCompositor.setBackground(entry.value);
  } else {
    // Add as overlay
    await videoCompositor.addOverlay(entry.key, entry.value);
  }
}
```

---

### 3. `captureTimedLayersAtTime()`

Captures only the layers that should be visible at a specific time point.

```dart
Future<Uint8List> captureTimedLayersAtTime({
  required int currentTime,
  bool includeNonTimedLayers = true,
})
```

**Parameters:**
- `currentTime` - The time in milliseconds to check layer visibility.
- `includeNonTimedLayers` - Whether to include regular (non-timed) layers.

**Returns:** `Uint8List` representing the image at the specified time.

**Example:**
```dart
// Capture what should be visible at 5 seconds
final frameAt5s = await editorState.captureTimedLayersAtTime(
  currentTime: 5000, // 5 seconds in milliseconds
);

// Capture only timed layers (exclude static layers)
final timedOnly = await editorState.captureTimedLayersAtTime(
  currentTime: 5000,
  includeNonTimedLayers: false,
);

// Generate video frames
for (int time = 0; time < videoDuration; time += 33) { // 30 FPS
  final frame = await editorState.captureTimedLayersAtTime(
    currentTime: time,
  );
  await videoEncoder.addFrame(frame);
}
```

## Use Cases

### Use Case 1: Video Rendering with Individual Layers

```dart
// Capture all layers individually
final layerImages = await editorState.captureLayersIndividually();

// Render video with compositing
for (int frame = 0; frame < totalFrames; frame++) {
  final currentTime = (frame / fps * 1000).toInt();
  
  // Start with background
  var frameImage = layerImages['background']!;
  
  // Composite each layer if it should be visible
  for (var layer in editorState.activeLayers) {
    if (layer is TimedTextLayer && layer.isVisibleAtTime(currentTime)) {
      frameImage = await compositeImages(
        frameImage,
        layerImages[layer.id]!,
        layer.offset,
        layer.rotation,
        layer.scale,
      );
    }
  }
  
  await videoEncoder.addFrame(frameImage);
}
```

### Use Case 2: Timeline Preview

```dart
// Generate thumbnail for timeline at specific time
Future<Uint8List> generateTimelineThumbnail(int timeMs) async {
  return await editorState.captureTimedLayersAtTime(
    currentTime: timeMs,
  );
}

// Create timeline with thumbnails every second
final thumbnails = <int, Uint8List>{};
for (int time = 0; time < videoDuration; time += 1000) {
  thumbnails[time] = await generateTimelineThumbnail(time);
}
```

### Use Case 3: Layer Export

```dart
// Export each layer as a separate file
Future<void> exportLayersSeparately() async {
  final layerImages = await editorState.captureLayersIndividually(
    includeBackground: false, // Skip background
  );
  
  for (var entry in layerImages.entries) {
    final layerId = entry.key;
    final imageBytes = entry.value;
    
    // Save to file
    final file = File('layer_$layerId.png');
    await file.writeAsBytes(imageBytes);
  }
}
```

### Use Case 4: Animated Transitions

```dart
// Fade in a layer over time
Future<List<Uint8List>> generateFadeInFrames(
  String layerId,
  int startTime,
  int duration,
) async {
  final frames = <Uint8List>[];
  final fps = 30;
  final frameCount = (duration / 1000 * fps).toInt();
  
  for (int i = 0; i < frameCount; i++) {
    final currentTime = startTime + (i * 1000 / fps).toInt();
    final frame = await editorState.captureTimedLayersAtTime(
      currentTime: currentTime,
    );
    frames.add(frame);
  }
  
  return frames;
}
```

## Performance Considerations

### Optimization Tips

1. **Batch Captures**: If capturing multiple frames, reuse layer images when possible
   ```dart
   // Capture layers once
   final layerImages = await captureLayersIndividually();
   
   // Reuse for multiple frames
   for (int time = 0; time < duration; time += frameInterval) {
     // Composite from cached layer images
     final frame = compositeFromCache(layerImages, time);
   }
   ```

2. **Async Processing**: Use isolates for heavy image processing
   ```dart
   final layerImages = await captureLayersIndividually();
   
   // Process in isolate
   final processedFrames = await compute(
     processFramesInIsolate,
     layerImages,
   );
   ```

3. **Progressive Rendering**: For long videos, render in chunks
   ```dart
   const chunkSize = 300; // 10 seconds at 30fps
   for (int chunk = 0; chunk < totalFrames; chunk += chunkSize) {
     final frames = await renderChunk(chunk, chunkSize);
     await saveChunk(frames);
   }
   ```

## Integration with Video Editors

### Example: FFmpeg Integration

```dart
Future<void> renderVideoWithLayers() async {
  // 1. Capture all layers
  final layerImages = await editorState.captureLayersIndividually();
  
  // 2. Save background as base video frame
  final bgFile = File('background.png');
  await bgFile.writeAsBytes(layerImages['background']!);
  
  // 3. Create FFmpeg filter complex for each timed layer
  final filters = <String>[];
  for (var layer in editorState.activeLayers) {
    if (layer is TimedTextLayer) {
      // Save layer image
      final layerFile = File('layer_${layer.id}.png');
      await layerFile.writeAsBytes(layerImages[layer.id]!);
      
      // Add FFmpeg overlay filter with timing
      filters.add(
        'overlay=x=${layer.offset.dx}:y=${layer.offset.dy}:'
        'enable=\'between(t,${layer.startTime / 1000},${layer.endTime / 1000})\'',
      );
    }
  }
  
  // 4. Run FFmpeg
  final command = 'ffmpeg -i background.png ${filters.join(' ')} output.mp4';
  await Process.run('ffmpeg', command.split(' '));
}
```

## Error Handling

```dart
try {
  final layerImages = await editorState.captureLayersIndividually();
  
  if (layerImages.isEmpty) {
    print('No layers to capture');
    return;
  }
  
  // Process images...
} catch (e) {
  print('Error capturing layers: $e');
  // Handle error
}
```

## Best Practices

1. **Always await captures**: These are async operations
2. **Check for empty results**: Handle cases where capture fails
3. **Clean up resources**: Dispose of image data when done
4. **Use appropriate delays**: Give UI time to update (100ms recommended)
5. **Test with different layer counts**: Performance varies with complexity

## Limitations

- Captures are taken at current editor state
- UI must be mounted and visible
- Large layer counts may impact performance
- Delay of ~100ms per capture for UI updates

## See Also

- [TIMED_LAYERS.md](./TIMED_LAYERS.md) - Timed layer system documentation
- [Main Editor API](./README.md) - Complete editor API reference

