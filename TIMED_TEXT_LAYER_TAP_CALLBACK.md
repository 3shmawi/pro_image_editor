# Timed Text Layer Tap Callback

## Overview

The `onTimedTextLayerTap` callback has been added to handle tap events specifically for `TimedTextLayer` instances, separate from regular `TextLayer` tap handling.

## Implementation Details

### 1. Main Editor (`main_editor.dart`)

Added a private method `_onTimedTextLayerTap` that:
- Accepts a `TimedTextLayer` parameter
- Retrieves the total duration from the video controller (if available) or uses a default of 10000ms
- Opens the `TimedTextEditor` with the layer data
- Updates the layer properties after editing
- Removes the layer if the text is empty

```dart
void _onTimedTextLayerTap(TimedTextLayer layerData) async {
  // Get total duration from video controller or use default
  final totalDuration = _isVideoEditor
      ? widget.videoController?.videoDuration.inMilliseconds ?? 10000
      : 10000;

  // Open timed text editor
  TimedTextLayer? updatedLayer = await openPage(
    TimedTextEditor(
      layer: _layerCopyManager.copyLayer(layerData) as TimedTextLayer,
      heroTag: layerData.id,
      configs: configs,
      theme: _theme,
      callbacks: callbacks,
      scaleFactor: textEditorConfigs.enableMainEditorZoomFactor
          ? interactiveViewer.currentState?.scaleFactor ?? 1.0
          : 1.0,
      imageSize: sizesManager.decodedImageSize,
      totalDuration: totalDuration,
    ),
    duration: const Duration(milliseconds: 250),
  );

  // Update layer properties...
}
```

### 2. Main Editor Layers Widget (`main_editor_layers.dart`)

- Added `onTimedTextLayerTap` parameter to the constructor
- Added field declaration: `final Function(TimedTextLayer layer) onTimedTextLayerTap;`
- Passed the callback to `MainEditorLayersService`
- Added import for `TimedTextLayer`

### 3. Main Editor Layers Service (`main_editor_layers_service.dart`)

Updated two methods to handle `TimedTextLayer` taps:

#### `handleEditTap` Method
Checks for `isTimedTextLayer` first, before checking `isTextLayer`:

```dart
void handleEditTap(Layer layer) {
  if (layer.isTimedTextLayer) {
    onTimedTextLayerTap(layer as TimedTextLayer);
  } else if (layer.isTextLayer) {
    onTextLayerTap(layer as TextLayer);
  } else if (layer.isPaintLayer) {
    onEditPaintLayer(layer as PaintLayer);
  } else if (layer.isWidgetLayer) {
    callbacks.stickerEditorCallbacks?.onTapEditSticker
        ?.call(state, layer as WidgetLayer);
  }
}
```

#### `handleLayerTap` Method
Similar check for timed text layers when edit is enabled:

```dart
} else if (layer.interaction.enableEdit) {
  if (layer.isTimedTextLayer && configs.textEditor.enableEdit) {
    onTimedTextLayerTap(layer as TimedTextLayer);
  } else if (layer.isTextLayer && configs.textEditor.enableEdit) {
    onTextLayerTap(layer as TextLayer);
  } else if (layer.isPaintLayer && configs.paintEditor.enableEdit) {
    onEditPaintLayer(layer as PaintLayer);
  }
}
```

## Key Features

1. **Automatic Type Detection**: The system automatically detects whether a layer is a `TimedTextLayer` or regular `TextLayer` and calls the appropriate callback.

2. **Video Duration Integration**: For video editors, the callback automatically retrieves the video duration from the `videoController` to pass to the `TimedTextEditor`.

3. **Consistent Behavior**: The callback follows the same pattern as `onTextLayerTap`, ensuring consistent user experience.

4. **Priority Handling**: `isTimedTextLayer` is checked before `isTextLayer` to ensure timed text layers are handled correctly (since `TimedTextLayer` extends `TextLayer` conceptually but returns `false` for `isTextLayer`).

## Usage

The callback is automatically invoked when:
- A user taps on a `TimedTextLayer` in the editor
- The layer's `interaction.enableEdit` is `true`
- The `configs.textEditor.enableEdit` is `true`

No manual invocation is required - the system handles it automatically through the layer interaction system.

## Related Files

- `/lib/features/main_editor/main_editor.dart` - Main editor implementation
- `/lib/features/main_editor/widgets/main_editor_layers.dart` - Layers widget
- `/lib/features/main_editor/services/main_editor_layers_service.dart` - Layer interaction service
- `/lib/core/models/timed_layers/timed_text_layer.dart` - Timed text layer model
- `/lib/features/timed_text_editor/timed_text_editor.dart` - Timed text editor

