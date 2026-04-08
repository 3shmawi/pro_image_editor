# Timed Layers Implementation

## Overview

Timed layers extend the existing layer system in ProImageEditor to support time-based visibility. This feature is essential for video editing and time-based animations, allowing layers to appear and disappear at specific times in a timeline.

## Architecture

### Base Class: `TimedLayer`

The `TimedLayer` class extends the base `Layer` class and adds timing functionality:

```dart
class TimedLayer extends Layer {
  int startTime;  // Start time in milliseconds
  int endTime;    // End time in milliseconds
  
  int get duration => endTime - startTime;
  bool isVisibleAtTime(int currentTime) { ... }
}
```

### Specialized Timed Layer Types

Following the existing layer pattern, we've created four specialized timed layer types:

1. **TimedTextLayer** - Text with timing
2. **TimedEmojiLayer** - Emojis with timing
3. **TimedPaintLayer** - Paint/drawings with timing
4. **TimedWidgetLayer** - Custom widgets/stickers with timing

## File Structure

```
lib/core/models/timed_layers/
├── timed_layer.dart          # Base timed layer class
├── timed_text_layer.dart     # Timed text layer
├── timed_emoji_layer.dart    # Timed emoji layer
├── timed_paint_layer.dart    # Timed paint layer
└── timed_widget_layer.dart   # Timed widget/sticker layer

lib/features/text_editor/
├── timed_text_editor.dart    # Timed text editor widget
└── widgets/
    └── timed_text_editor_timeline.dart  # Timeline UI component
```

## Key Features

### 1. Time Management
- **startTime**: When the layer becomes visible (milliseconds)
- **endTime**: When the layer becomes invisible (milliseconds)
- **duration**: Calculated property (endTime - startTime)
- **isVisibleAtTime(currentTime)**: Check if layer should be visible at a given time

### 2. Serialization Support
- Full `toMap()` and `fromMap()` support
- Compatible with existing import/export system
- Supports minification for optimized storage

### 3. Type Safety
- Each timed layer has a unique type identifier:
  - `timedText`
  - `timedEmoji`
  - `timedPaint`
  - `timedWidget`/`timedSticker`

### 4. Validation
- Assertions ensure `startTime >= 0`
- Assertions ensure `endTime > startTime`

## Usage Example

### Creating Timed Layers Programmatically

```dart
// Create a timed text layer that appears from 2s to 7s
final timedText = TimedTextLayer(
  text: 'Hello World',
  startTime: 2000,  // 2 seconds
  endTime: 7000,    // 7 seconds
  offset: Offset(100, 100),
  color: Colors.white,
  background: Colors.black,
  scale: 1.5,
);

// Check if visible at 5 seconds
if (timedText.isVisibleAtTime(5000)) {
  // Render the layer
}

// Get duration
print('Duration: ${timedText.duration}ms'); // 5000ms
```

### Using the Timed Text Editor

```dart
// Open the timed text editor
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => TimedTextEditor(
      layer: existingLayer, // Optional: edit existing layer
      totalDuration: 10000, // 10 seconds total timeline
      theme: Theme.of(context),
      configs: ProImageEditorConfigs(),
      callbacks: ProImageEditorCallbacks(),
    ),
  ),
);

if (result is TimedTextLayer) {
  // Use the created/edited timed text layer
  print('Text: ${result.text}');
  print('Start: ${result.startTime}ms');
  print('End: ${result.endTime}ms');
}
```

## Integration Plan

### Phase 1: Core Integration (Current - Model & Editor) ✅
- [x] Create timed layer models
- [x] Implement serialization/deserialization
- [x] Add validation and type checking
- [x] Ensure linting compliance
- [x] Create TimedTextEditor widget
- [x] Implement timeline UI component

### Phase 2: State Management Integration
- [ ] Update `StateManager` to handle timed layers
- [ ] Modify state history to track timing changes
- [ ] Add timeline position tracking
- [ ] Implement time-based layer filtering

### Phase 3: UI Components
- [ ] Create timeline widget for visualizing layers
- [ ] Add time scrubber/playhead
- [ ] Implement layer duration editing UI
- [ ] Add time markers and snap-to-grid

### Phase 4: Editor Integration
- [ ] Update `MainEditor` to support timed layers
- [ ] Modify layer rendering to respect timing
- [ ] Add timeline controls to main editor
- [ ] Implement time-based layer visibility toggling

### Phase 5: Video Editor Enhancement
- [ ] Integrate with existing video editor
- [ ] Sync layers with video playback
- [ ] Add video timeline scrubbing
- [ ] Support frame-accurate positioning

### Phase 6: Advanced Features
- [ ] Layer animations (fade in/out)
- [ ] Transition effects between layers
- [ ] Keyframe support for layer properties
- [ ] Timeline zooming and panning

## Technical Considerations

### 1. Backward Compatibility
- Timed layers are separate from regular layers
- Existing layer system remains unchanged
- Can convert regular layers to timed layers if needed

### 2. Performance
- Time-based filtering should be efficient
- Consider caching visible layers for current time
- Optimize rendering for video playback scenarios

### 3. State History
- Timeline changes should be tracked in undo/redo
- Consider separate history for timeline edits vs layer edits

### 4. Export/Import
- Timed layers fully support serialization
- Compatible with existing import/export system
- Can be stored in state history

## API Reference

### TimedLayer

```dart
class TimedLayer extends Layer {
  // Constructor
  TimedLayer({
    required int startTime,
    required int endTime,
    // ... other Layer properties
  });
  
  // Properties
  int startTime;
  int endTime;
  int get duration;
  bool get isTimedLayer;
  
  // Methods
  bool isVisibleAtTime(int currentTime);
  TimedLayer copyWith({ ... });
  Map<String, dynamic> toMap({ ... });
  static TimedLayer fromMap(Map<String, dynamic> map);
}
```

### TimedTextLayer

```dart
class TimedTextLayer extends TimedLayer {
  // Inherits all TimedLayer properties plus:
  String text;
  Color color;
  Color background;
  TextAlign align;
  double fontScale;
  TextStyle? textStyle;
  // ... other text properties
}
```

### TimedEmojiLayer

```dart
class TimedEmojiLayer extends TimedLayer {
  // Inherits all TimedLayer properties plus:
  String emoji;
}
```

### TimedPaintLayer

```dart
class TimedPaintLayer extends TimedLayer {
  // Inherits all TimedLayer properties plus:
  PaintedModel item;
  Size rawSize;
  double opacity;
  Size get size;
}
```

### TimedWidgetLayer

```dart
class TimedWidgetLayer extends TimedLayer {
  // Inherits all TimedLayer properties plus:
  Widget widget;
  WidgetLayerExportConfigs exportConfigs;
}
```

## Testing Strategy

### Unit Tests
```dart
// Test timing validation
test('startTime must be non-negative', () { ... });
test('endTime must be greater than startTime', () { ... });

// Test visibility
test('isVisibleAtTime returns correct value', () { ... });

// Test serialization
test('toMap and fromMap preserve all properties', () { ... });

// Test duration calculation
test('duration is calculated correctly', () { ... });
```

### Integration Tests
- Test with state manager
- Test with main editor
- Test with video editor
- Test import/export functionality

## Migration Guide

### Converting Regular Layers to Timed Layers

```dart
// Regular layer
final textLayer = TextLayer(
  text: 'Hello',
  offset: Offset(100, 100),
);

// Convert to timed layer
final timedTextLayer = TimedTextLayer(
  text: textLayer.text,
  offset: textLayer.offset,
  startTime: 0,
  endTime: 5000,
  // ... copy other properties
);
```

### Working with Mixed Layers

```dart
// Filter layers by time
List<Layer> getVisibleLayers(List<Layer> layers, int currentTime) {
  return layers.where((layer) {
    if (layer is TimedLayer) {
      return layer.isVisibleAtTime(currentTime);
    }
    return true; // Regular layers are always visible
  }).toList();
}
```

## Future Enhancements

1. **Easing Functions**: Add animation curves for layer transitions
2. **Keyframes**: Support property changes over time
3. **Layer Groups**: Group timed layers for synchronized timing
4. **Templates**: Predefined timing patterns for common use cases
5. **Audio Sync**: Sync layers with audio tracks
6. **Multi-track Timeline**: Support multiple timeline tracks

## Contributing

When contributing to timed layers:

1. Follow the existing layer pattern
2. Ensure all properties are serializable
3. Add comprehensive tests
4. Update this documentation
5. Maintain backward compatibility

## Questions & Discussion

For questions or discussions about timed layers:
- Open an issue on GitHub
- Tag with `enhancement` and `timed-layers`
- Reference this document in discussions

---

**Status**: Phase 1 Complete (Models Implemented)
**Last Updated**: 2025-11-25
**Author**: ProImageEditor Contributors

