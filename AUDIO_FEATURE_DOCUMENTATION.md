# Audio Feature Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Features](#features)
4. [User Guide](#user-guide)
5. [Developer Guide](#developer-guide)
6. [API Reference](#api-reference)
7. [Troubleshooting](#troubleshooting)
8. [Examples](#examples)

---

## Overview

The Audio Feature allows users to add, edit, and manage multiple audio layers in video editing projects. It provides a professional timeline-based interface for precise audio positioning and synchronization with video content.

### Key Capabilities
- **Multiple Audio Layers:** Add unlimited audio tracks to your video
- **Timeline Visualization:** See all audio layers in a visual timeline
- **Precise Timing:** Control start time and duration for each audio layer
- **Real-time Playback:** Audio plays synchronized with video during editing
- **Progress Tracking:** Visual feedback during audio export with FFmpeg
- **Non-destructive Editing:** Original video remains unchanged until final export

### Supported Platforms
- ✅ iOS
- ✅ Android
- ✅ macOS
- ✅ Linux
- ✅ Windows

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Main Editor                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  Video Display                         │  │
│  │              (with audio playback)                     │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Audio Timeline Bar                        │  │
│  │  [Audio 1]────────                                     │  │
│  │      [Audio 2]────────────                            │  │
│  │          [Audio 3]───────                             │  │
│  └───────────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Bottom Toolbar                            │  │
│  │  [Paint] [Text] [Audio] [Filters] ...                │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. **AudioLayer Model** (`lib/core/models/layers/audio_layer.dart`)
- Represents a single audio track
- Properties: path, duration, startTime, endTime
- Follows the same pattern as other layer types (TextLayer, PaintLayer, etc.)

#### 2. **Audio Timeline Bar** (`lib/features/audio_editor/widgets/audio_timeline_bar.dart`)
- Visual representation of all audio layers
- Shows audio position, duration, and overlap
- Interactive - tap to edit layers

#### 3. **Audio Editor Dialog** (`lib/features/audio_editor/audio_editor_dialog.dart`)
- Edit individual audio layer properties
- Adjust start time with slider
- Delete audio layers
- Visual preview of audio position

#### 4. **Audio Recorder Widget** (`lib/features/audio_editor/widgets/audio_recorder_widget.dart`)
- Record new audio or select existing files
- Integrated into main editor workflow

#### 5. **FFmpeg Export Service** (`lib/features/main_editor/services/ffmpeg_export_service.dart`)
- Merges multiple audio layers with video
- Handles audio synchronization and mixing
- Reports progress during export

#### 6. **FFmpeg Progress Dialog** (`lib/features/audio_editor/widgets/ffmpeg_progress_dialog.dart`)
- Shows real-time export progress
- Displays percentage and status messages
- Professional user feedback

---

## Features

### 1. Multi-Layer Audio Support

Add multiple audio tracks to a single video:
- **Background Music:** Add music tracks
- **Sound Effects:** Layer sound effects at specific times
- **Voiceovers:** Record or add voice narration
- **Ambient Audio:** Add environmental sounds

**Technical Details:**
- Unlimited audio layers (limited only by device performance)
- Each layer has independent timing
- Layers can overlap for complex audio mixing
- Original video audio is preserved and mixed with new layers

### 2. Visual Timeline

Professional timeline interface showing:
- **Audio Bars:** Color-coded horizontal bars for each layer
- **Duration Visualization:** Bar length represents audio duration
- **Position Indicator:** Shows where audio starts in the video
- **Current Time Marker:** Red line showing current playback position
- **Thumbnail Background:** Video thumbnails for context
- **Overlap Detection:** Visual indication when multiple audios play together

**Timeline Features:**
- Responsive design (adapts to screen size)
- Smooth animations
- Touch/click interaction
- Auto-stacking (up to 3 rows for multiple layers)

### 3. Precise Timing Control

Control exactly when audio plays:
- **Start Time:** Millisecond-precision positioning
- **Duration:** Automatically calculated from audio file
- **End Time:** Calculated as startTime + duration
- **Slider Control:** Easy adjustment with visual feedback
- **Timeline Preview:** See audio position before saving

### 4. Real-time Playback Synchronization

Audio plays in sync with video during editing:
- **Automatic Sync:** Audio starts/stops with video playback
- **Seek Support:** Audio follows video scrubbing
- **Pause/Resume:** Audio pauses when video pauses
- **Multiple Layers:** All active audio layers play simultaneously
- **Accurate Timing:** Millisecond-precision synchronization

### 5. FFmpeg Export with Progress

Professional export with visual feedback:
- **Progress Bar:** Animated progress indicator (0-100%)
- **Percentage Display:** Real-time completion percentage
- **Status Messages:** Contextual messages during export
  - "Preparing audio layers..."
  - "Mixing audio with video..."
  - "Finalizing export..."
  - "Export complete!"
- **Completion State:** Visual confirmation when done
- **Error Handling:** Clear error messages if export fails

### 6. Audio Layer Management

Complete CRUD operations:
- **Create:** Record or add audio files
- **Read:** View all audio layers in timeline
- **Update:** Edit start time and properties
- **Delete:** Remove audio layers with confirmation

---

## User Guide

### Adding Audio to Video

#### Step 1: Open Video Editor
```dart
ProImageEditor.video(
  videoController,
  configs: ProImageEditorConfigs(
    mainEditor: MainEditorConfigs(
      tools: [
        SubEditorMode.audio,  // Enable audio tool
        // ... other tools
      ],
    ),
  ),
);
```

#### Step 2: Add Audio Layer
1. Tap the **Audio** button in the bottom toolbar
2. Record new audio or select existing file
3. Audio layer is created at current video playback position
4. Audio timeline automatically appears above toolbar

#### Step 3: Edit Audio Layer (Optional)
1. Tap on audio bar in timeline
2. Audio editor dialog opens
3. Adjust start time with slider
4. Preview position on timeline
5. Tap **Save** to apply changes

#### Step 4: Add More Layers (Optional)
1. Repeat steps 2-3 to add more audio layers
2. Each layer appears in the timeline
3. Layers can overlap for complex audio mixing

#### Step 5: Export Video
1. Tap **Done** button
2. Progress dialog shows export status
3. Wait for completion (progress bar fills 0-100%)
4. Video is exported with all audio layers mixed

### Editing Audio Layers

#### Adjust Start Time
1. Tap audio layer in timeline
2. Use slider to adjust start time
3. Visual preview shows new position
4. Tap **Save** to apply

#### Delete Audio Layer
1. Tap audio layer in timeline
2. Tap **Delete** button
3. Confirm deletion
4. Layer is removed from timeline

#### View Audio Information
Audio editor dialog shows:
- **Filename:** Name of audio file
- **Duration:** Total length of audio
- **Start Time:** When audio begins in video
- **End Time:** When audio ends in video

### Timeline Interaction

#### Understanding the Timeline
```
┌────────────────────────────────────────────────┐
│ Audio Layers (3)              00:05.2          │ ← Header
├────────────────────────────────────────────────┤
│ [Thumbnails]                                   │ ← Video context
├────────────────────────────────────────────────┤
│ [Blue Bar]──────                               │ ← Audio layer 1
│     [Green Bar]────────────                    │ ← Audio layer 2
│         [Orange Bar]───────                    │ ← Audio layer 3
│                    │                           │
│                    └─ Current time indicator   │
└────────────────────────────────────────────────┘
```

#### Color Coding
- **Blue:** First audio layer
- **Green:** Second audio layer
- **Orange:** Third audio layer
- **Purple, Teal, Pink, Amber, Cyan:** Additional layers
- **Red Line:** Current playback position

#### Timeline Controls
- **Tap Audio Bar:** Open editor for that layer
- **Observe Overlaps:** See when multiple audios play together
- **Watch Indicator:** Red line moves during playback

---

## Developer Guide

### Integration

#### 1. Enable Audio Feature

Add audio tool to main editor configuration:

```dart
ProImageEditor.video(
  videoController,
  configs: ProImageEditorConfigs(
    mainEditor: MainEditorConfigs(
      tools: [
        SubEditorMode.audio,  // Enable audio button
        SubEditorMode.paint,
        SubEditorMode.text,
        // ... other tools
      ],
    ),
  ),
);
```

#### 2. Handle Export Callback

Receive exported video with audio:

```dart
ProImageEditor.video(
  videoController,
  callbacks: ProImageEditorCallbacks(
    onImageEditingComplete: (Uint8List bytes) async {
      // bytes contains the final video with mixed audio
      final file = File('output.mp4');
      await file.writeAsBytes(bytes);
      print('Video exported: ${file.path}');
    },
  ),
);
```

#### 3. Custom Audio Recording (Optional)

Provide custom audio recording implementation:

```dart
// The default audio recorder widget can be customized
// by extending AudioRecorderWidget or providing your own
```

### Data Model

#### AudioLayer Structure

```dart
class AudioLayer extends Layer {
  /// Path to the audio file
  final String path;
  
  /// Duration in milliseconds
  final int duration;
  
  /// Start time in milliseconds
  final int startTime;
  
  /// End time (calculated)
  int get endTime => startTime + duration;
  
  /// Check if audio should play at given time
  bool isPlayingAtTime(int currentTime) {
    return currentTime >= startTime && currentTime < endTime;
  }
}
```

#### Serialization

AudioLayer supports full serialization:

```dart
// To JSON
final json = audioLayer.toMap();
// {
//   'path': '/path/to/audio.m4a',
//   'duration': 5000,
//   'startTime': 2000,
//   'type': 'audio',
//   ...
// }

// From JSON
final layer = AudioLayer.fromMap(json, id: 'unique-id');
```

### FFmpeg Integration

#### Audio Mixing Command

The service generates FFmpeg commands like:

```bash
ffmpeg \
  -i "video.mp4" \           # Input video
  -i "audio1.m4a" \          # Audio layer 1
  -i "audio2.m4a" \          # Audio layer 2
  -filter_complex "
    [1:a]adelay=2000|2000[a1];    # Delay audio 1 by 2 seconds
    [2:a]adelay=5000|5000[a2];    # Delay audio 2 by 5 seconds
    [0:a][a1][a2]amix=inputs=3:duration=first[aout]
  " \
  -map 0:v \                 # Map video
  -map "[aout]" \            # Map mixed audio
  -c:v copy \                # Copy video (no re-encode)
  -c:a aac \                 # Encode audio as AAC
  -b:a 192k \                # Audio bitrate
  -y "output.mp4"            # Output file
```

#### Progress Tracking

FFmpeg reports progress through statistics:

```dart
FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
  final timeInMs = statistics.getTime();
  final progress = timeInMs / videoDurationMs;
  onProgress(progress); // 0.0 to 1.0
});
```

### Customization

#### Custom Timeline Colors

Modify `_getLayerColor()` in `audio_timeline_bar.dart`:

```dart
Color _getLayerColor(int index) {
  final colors = [
    Colors.blue,      // Your custom colors
    Colors.green,
    Colors.orange,
    // ... add more colors
  ];
  return colors[index % colors.length];
}
```

#### Custom Progress Messages

Modify progress callback in `main_editor.dart`:

```dart
onProgress: (progress) {
  if (progress < 0.3) {
    messageNotifier.value = 'Your custom message...';
  } else if (progress < 0.7) {
    messageNotifier.value = 'Another message...';
  }
  // ...
}
```

#### Custom Audio Recorder

Replace the default audio recorder widget:

```dart
// In main_editor.dart, modify openAudioEditor()
void openAudioEditor() async {
  await showModalBottomSheet(
    context: context,
    builder: (context) {
      return YourCustomAudioRecorderWidget(
        onStop: (path, duration) {
          // Add audio layer
          addLayer(AudioLayer(
            path: path,
            duration: duration.inMilliseconds,
            startTime: currentTime.inMilliseconds,
          ));
        },
      );
    },
  );
}
```

---

## API Reference

### AudioLayer

#### Constructor
```dart
AudioLayer({
  required String path,
  required int duration,
  int startTime = 0,
  String? id,
  Offset? offset,
  double? rotation,
  double? scale,
  bool? flipX,
  bool? flipY,
})
```

#### Properties
- `path` (String): Path to audio file
- `duration` (int): Duration in milliseconds
- `startTime` (int): Start time in milliseconds
- `endTime` (int): End time (getter, calculated)

#### Methods
- `isPlayingAtTime(int currentTime)`: Check if audio should play
- `toMap()`: Serialize to JSON
- `fromMap(Map<String, dynamic> map)`: Deserialize from JSON
- `copyWith({...})`: Create copy with modified properties

### AudioTimelineBar

#### Constructor
```dart
AudioTimelineBar({
  required List<AudioLayer> audioLayers,
  required int totalDuration,
  required ValueNotifier<Duration> currentTimeNotifier,
  required ValueChanged<AudioLayer> onAudioLayerTap,
  required ThemeData theme,
  ValueNotifier<List<ImageProvider>?>? thumbnails,
})
```

#### Properties
- `audioLayers`: List of audio layers to display
- `totalDuration`: Total video duration in milliseconds
- `currentTimeNotifier`: Current playback time notifier
- `onAudioLayerTap`: Callback when layer is tapped
- `theme`: Theme for styling
- `thumbnails`: Optional video thumbnails

### AudioEditorDialog

#### Constructor
```dart
AudioEditorDialog({
  required AudioLayer audioLayer,
  required int totalDuration,
  required ThemeData theme,
  ValueNotifier<List<ImageProvider>?>? thumbnails,
})
```

#### Returns
- `AudioLayer`: Updated layer (if saved)
- `'delete'`: String indicating deletion request
- `null`: Cancelled (no changes)

### FfmpegExportService

#### mergeAudioIntoVideo()
```dart
Future<String?> mergeAudioIntoVideo({
  required String videoPath,
  required List<AudioLayer> audioLayers,
  String? outputPath,
  void Function(double progress)? onProgress,
  int? videoDurationMs,
})
```

**Parameters:**
- `videoPath`: Path to input video file
- `audioLayers`: List of audio layers to merge
- `outputPath`: Optional output path (auto-generated if null)
- `onProgress`: Optional progress callback (0.0 to 1.0)
- `videoDurationMs`: Video duration for progress calculation

**Returns:**
- `String?`: Path to output video (null if failed)

### FfmpegProgressDialog

#### Constructor
```dart
FfmpegProgressDialog({
  required double progress,
  required ThemeData theme,
  String? message,
})
```

#### FfmpegProgressDialogController
```dart
FfmpegProgressDialogController({
  required ValueNotifier<double> progressNotifier,
  required ThemeData theme,
  ValueNotifier<String?>? messageNotifier,
})
```

---

## Troubleshooting

### Common Issues

#### 1. Progress Dialog Not Showing

**Symptoms:**
- No dialog appears when exporting
- Simple spinner instead of progress bar

**Solutions:**
1. Verify you're using the latest code
2. Check that audio layers exist: `audioLayers.isNotEmpty`
3. Ensure video controller is not null
4. Run in debug mode and check logs

**Debug:**
```dart
print('Audio layers: ${activeLayers.whereType<AudioLayer>().length}');
print('Video controller: ${widget.videoController != null}');
```

#### 2. No Progress Updates

**Symptoms:**
- Dialog shows but stays at 0%
- No progress bar movement

**Solutions:**
1. Check FFmpeg statistics callback is enabled
2. Verify video duration is valid (> 0)
3. Ensure FFmpeg is processing (check logs)
4. Check audio files are accessible

**Debug Logs:**
```
Setting up progress callback...
Video duration: 10000 ms
FFmpeg progress: X.X%
```

#### 3. Audio Not Playing During Editing

**Symptoms:**
- Video plays but no audio
- Audio layers visible but silent

**Solutions:**
1. Check audio file format is supported
2. Verify audio file path is correct
3. Check device volume is not muted
4. Ensure AudioPlayer is initialized

**Debug:**
```dart
final file = File(audioLayer.path);
print('Audio exists: ${await file.exists()}');
print('Audio size: ${await file.length()}');
```

#### 4. Export Fails

**Symptoms:**
- Progress dialog closes immediately
- No output file generated
- Error in logs

**Solutions:**
1. Check FFmpeg return code in logs
2. Verify all audio files exist
3. Check audio format compatibility
4. Ensure sufficient storage space
5. Check file permissions

**Debug Logs:**
```
FFmpeg failed with return code: X
Logs: [error details]
```

#### 5. Audio Out of Sync

**Symptoms:**
- Audio plays at wrong time
- Audio doesn't match video

**Solutions:**
1. Verify start time is set correctly
2. Check video and audio frame rates match
3. Ensure no audio drift during playback
4. Re-export video

**Debug:**
```dart
print('Audio start: ${audioLayer.startTime}ms');
print('Video time: ${videoController.playTimeNotifier.value.inMilliseconds}ms');
```

### Debug Mode

Enable comprehensive logging:

```bash
flutter run --debug --verbose
```

Look for these log patterns:

**Successful Export:**
```
Starting audio export...
Video path: /path/to/video.mp4
Audio layers: 2
FFmpeg command: ...
Setting up progress callback...
FFmpeg progress: 25.5%
FFmpeg progress: 50.2%
FFmpeg progress: 75.8%
FFmpeg progress: 100.0%
FFmpeg execution completed with return code: 0
Reading output file: 1234567 bytes
```

**Failed Export:**
```
Starting audio export...
FFmpeg failed with return code: 1
ERROR: FFmpeg merge failed - no output path
```

### Performance Issues

#### Slow Export

**Causes:**
- Large video files
- Multiple audio layers
- Complex audio mixing
- Slow device

**Solutions:**
1. Use shorter videos for testing
2. Reduce number of audio layers
3. Use compressed audio formats
4. Test on faster device

#### UI Lag

**Causes:**
- Too many progress updates
- Large timeline with many layers
- Heavy UI rendering

**Solutions:**
1. Throttle progress updates
2. Limit visible layers in timeline
3. Optimize rendering

---

## Examples

### Example 1: Basic Audio Addition

```dart
import 'package:pro_image_editor/pro_image_editor.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoEditorPage(),
    );
  }
}

class VideoEditorPage extends StatefulWidget {
  @override
  _VideoEditorPageState createState() => _VideoEditorPageState();
}

class _VideoEditorPageState extends State<VideoEditorPage> {
  ProVideoController? videoController;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    // Load your video
    final file = File('path/to/video.mp4');
    videoController = ProVideoController.file(file);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (videoController == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProImageEditor.video(
      videoController!,
      configs: ProImageEditorConfigs(
        mainEditor: MainEditorConfigs(
          tools: [
            SubEditorMode.audio,  // Enable audio
            SubEditorMode.paint,
            SubEditorMode.text,
          ],
        ),
      ),
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (bytes) async {
          // Save exported video
          final output = File('output.mp4');
          await output.writeAsBytes(bytes);
          print('Video saved: ${output.path}');
        },
      ),
    );
  }
}
```

### Example 2: Programmatic Audio Addition

```dart
// Add audio layer programmatically
void addBackgroundMusic() {
  final audioLayer = AudioLayer(
    path: '/path/to/music.mp3',
    duration: 30000,  // 30 seconds in milliseconds
    startTime: 0,     // Start at beginning
  );
  
  // Add to editor
  editorState.addLayer(audioLayer);
}

// Add sound effect at specific time
void addSoundEffect() {
  final soundEffect = AudioLayer(
    path: '/path/to/effect.wav',
    duration: 2000,   // 2 seconds
    startTime: 5000,  // Start at 5 seconds
  );
  
  editorState.addLayer(soundEffect);
}
```

### Example 3: Custom Progress Handling

```dart
// Custom progress dialog with your own UI
void exportWithCustomProgress() async {
  final progressNotifier = ValueNotifier<double>(0.0);
  
  // Show your custom dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Exporting Video'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, _) {
              return Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  SizedBox(height: 8),
                  Text('${(progress * 100).toInt()}%'),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
  
  // Export with progress callback
  final service = FfmpegExportService();
  final output = await service.mergeAudioIntoVideo(
    videoPath: videoPath,
    audioLayers: audioLayers,
    videoDurationMs: videoDuration,
    onProgress: (progress) {
      progressNotifier.value = progress;
    },
  );
  
  Navigator.pop(context);
  
  if (output != null) {
    print('Export complete: $output');
  }
}
```

### Example 4: Audio Layer Management

```dart
// Get all audio layers
List<AudioLayer> getAudioLayers() {
  return activeLayers.whereType<AudioLayer>().toList();
}

// Find audio at specific time
AudioLayer? findAudioAtTime(int timeMs) {
  return getAudioLayers().firstWhere(
    (layer) => layer.isPlayingAtTime(timeMs),
    orElse: () => null,
  );
}

// Remove all audio layers
void clearAllAudio() {
  final audioLayers = getAudioLayers();
  for (var layer in audioLayers) {
    removeLayer(layer);
  }
}

// Get total audio duration
int getTotalAudioDuration() {
  final audioLayers = getAudioLayers();
  if (audioLayers.isEmpty) return 0;
  
  return audioLayers
      .map((layer) => layer.endTime)
      .reduce((a, b) => a > b ? a : b);
}
```

### Example 5: Custom Timeline Styling

```dart
// Create custom audio timeline with your styling
class CustomAudioTimeline extends StatelessWidget {
  final List<AudioLayer> audioLayers;
  final int totalDuration;
  final ValueNotifier<Duration> currentTimeNotifier;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple, Colors.blue],
        ),
      ),
      child: AudioTimelineBar(
        audioLayers: audioLayers,
        totalDuration: totalDuration,
        currentTimeNotifier: currentTimeNotifier,
        onAudioLayerTap: (layer) {
          // Your custom edit handler
          showCustomEditDialog(layer);
        },
        theme: Theme.of(context),
      ),
    );
  }
}
```

---

## Best Practices

### 1. Audio File Management

**Recommended:**
- Use compressed audio formats (AAC, MP3)
- Keep audio files under 10MB for mobile
- Store audio in app's temporary directory
- Clean up temporary files after export

**Example:**
```dart
// Clean up after export
Future<void> cleanupAudioFiles(List<AudioLayer> layers) async {
  for (var layer in layers) {
    final file = File(layer.path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
```

### 2. Performance Optimization

**Tips:**
- Limit audio layers to 5-10 for best performance
- Use lower bitrate audio for mobile devices
- Avoid very long audio files (> 10 minutes)
- Test on target devices

### 3. User Experience

**Recommendations:**
- Show loading indicator during audio recording
- Provide visual feedback for all actions
- Allow undo/redo for audio operations
- Show file size estimates before export
- Provide audio preview before adding

### 4. Error Handling

**Best Practices:**
```dart
try {
  final output = await service.mergeAudioIntoVideo(
    videoPath: videoPath,
    audioLayers: audioLayers,
    videoDurationMs: videoDuration,
  );
  
  if (output == null) {
    // Show error to user
    showErrorDialog('Export failed. Please try again.');
  }
} catch (e) {
  // Log error
  print('Export error: $e');
  // Show user-friendly message
  showErrorDialog('An error occurred during export.');
}
```

### 5. Testing

**Test Cases:**
- Single audio layer
- Multiple overlapping layers
- Very short audio (< 1 second)
- Very long audio (> 5 minutes)
- Audio longer than video
- Audio starting near video end
- Export cancellation
- Low storage scenarios

---

## Changelog

### Version 1.0.0 (Current)
- ✅ Multi-layer audio support
- ✅ Visual timeline interface
- ✅ Real-time playback synchronization
- ✅ FFmpeg export with progress tracking
- ✅ Audio layer editing (start time adjustment)
- ✅ Audio layer deletion
- ✅ Comprehensive debug logging

### Future Enhancements
- 🔄 Volume control per layer
- 🔄 Fade in/out effects
- 🔄 Audio trimming (select portion of audio)
- 🔄 Mute original video audio option
- 🔄 Audio waveform visualization
- 🔄 Drag-and-drop timeline editing
- 🔄 Audio effects (reverb, echo, etc.)
- 🔄 Export cancellation
- 🔄 Background export

---

## Support

### Getting Help

1. **Check Documentation:** Review this guide and troubleshooting section
2. **Enable Debug Mode:** Run with `--debug` and check console logs
3. **Search Issues:** Check existing GitHub issues
4. **Create Issue:** Provide debug logs and reproduction steps

### Reporting Bugs

Include:
- Flutter version
- Platform (iOS/Android/Desktop)
- Device model
- Steps to reproduce
- Debug logs
- Expected vs actual behavior

### Contributing

Contributions welcome! Areas for improvement:
- Additional audio effects
- Performance optimizations
- UI/UX enhancements
- Documentation improvements
- Test coverage

---

## License

This feature is part of ProImageEditor and follows the same license terms.

---

## Acknowledgments

- **FFmpeg:** Audio mixing and video processing
- **flutter_sound:** Audio playback during editing
- **audioplayers:** Audio layer playback synchronization

---

**Last Updated:** December 2024  
**Version:** 1.0.0  
**Author:** ProImageEditor Team

