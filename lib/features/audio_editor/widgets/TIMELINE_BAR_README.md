# Layers Timeline Bar - All Timed Layers Visualization

## Overview

The `LayersTimelineBar` widget supports all timed layer types:
- **Audio Layers** (AudioLayer)
- **Timed Text Layers** (TimedTextLayer)
- **Timed Paint Layers** (TimedPaintLayer)
- **Video Bubble Layers** (VideoBubbleLayer)

## Features

### 1. Multi-Layer Type Support
The timeline now displays all timed layers in a unified view, making it easy to see when different elements appear during video playback.

### 2. Visual Differentiation
Each layer type has its own:
- **Color**: Blue (Audio), Green (Text), Orange (Paint), Purple (Video Bubble)
- **Icon**: Distinctive icons for each layer type
- **Label**: Shows relevant information (filename, text content, etc.)

### 3. Layer Count Chips
The header displays small chips showing the count of each layer type, providing a quick overview of the composition.

### 4. Smart Stacking
Layers are automatically stacked in up to 3 rows to prevent overlap while maintaining visibility.

## Usage

```dart
LayersTimelineBar(
  // Required parameters
  audioLayers: audioLayers,
  totalDuration: videoDuration,
  currentTimeNotifier: currentTimeNotifier,
  onAudioLayerTap: (layer) {
    // Handle audio layer tap
  },
  theme: Theme.of(context),
  
  // Optional timed layer parameters (new)
  timedTextLayers: textLayers,
  timedPaintLayers: paintLayers,
  videoBubbleLayers: bubbleLayers,
  thumbnails: thumbnailsNotifier,
)
```

## Parameters

### Required
- `audioLayers`: List of audio layers to display
- `totalDuration`: Total video duration in milliseconds
- `currentTimeNotifier`: ValueNotifier for current playback time
- `onAudioLayerTap`: Callback when an audio layer is tapped
- `theme`: ThemeData for styling

### Optional
- `timedTextLayers`: List of timed text layers (default: [])
- `timedPaintLayers`: List of timed paint layers (default: [])
- `videoBubbleLayers`: List of video bubble layers (default: [])
- `thumbnails`: ValueNotifier for video thumbnails

## Implementation Details

### Layer Bar Positioning
- Layers are positioned based on their `startTime` and `duration`
- Width is calculated as a proportion of the total duration
- Vertical position cycles through 3 rows using modulo arithmetic

### Layer Colors
- **Blue** (#2196F3): Audio layers
- **Green** (#4CAF50): Text layers
- **Orange** (#FF9800): Paint layers
- **Purple** (#9C27B0): Video bubble layers

### Tap Handling
- Audio layers: Implemented via `onAudioLayerTap` callback
- Other layers: Placeholder handlers (can be extended later)

## Future Enhancements

Potential improvements for future versions:
1. Add tap callbacks for other layer types
2. Implement drag-and-drop for layer repositioning
3. Add layer selection/highlighting
4. Support for layer editing from timeline
5. Zoom and pan controls for long videos
6. Layer grouping and organization features

## Technical Notes

- The widget is named `LayersTimelineBar` to reflect its expanded functionality
- All layer type parameters are optional with empty list defaults
- The timeline only shows when at least one layer exists
- Layer rendering is optimized using positioned widgets
- Current playback position is shown with a red vertical indicator

