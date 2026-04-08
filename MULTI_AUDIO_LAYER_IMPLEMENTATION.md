# Multi-Audio Layer Timeline Implementation

## Overview

This document describes the implementation of the multi-audio layer timeline feature for the ProImageEditor video editor. The implementation follows the same architectural pattern as the existing timed text and timed paint features, providing a consistent and professional user experience.

## Implementation Summary

### 1. AudioLayer Model Updates

**File:** `lib/core/models/layers/audio_layer.dart`

**Changes:**
- Changed `startTime` from `Duration` to `int` (milliseconds) for consistency with TimedLayer pattern
- Changed `duration` from `Duration` to `int` (milliseconds)
- Added `endTime` getter: `int get endTime => startTime + duration`
- Added `isPlayingAtTime(int currentTime)` method to check if audio should be playing at a given time
- Updated `toMap()`, `fromMap()`, and `copyWith()` methods to use int milliseconds

**Benefits:**
- Consistent with TimedTextLayer and TimedPaintLayer architecture
- More precise timing control
- Easier calculations and comparisons

### 2. Audio Timeline Bar Widget

**New File:** `lib/features/audio_editor/widgets/audio_timeline_bar.dart`

**Features:**
- Visual representation of all audio layers as horizontal bars
- Color-coded bars for different audio tracks (8 distinct colors)
- Current playback position indicator (red line)
- Video thumbnail background for context
- Timeline grid with second markers
- Displays audio filename, start time, and duration
- Tap to select and edit audio layers
- Automatic stacking of multiple layers (up to 3 rows)
- Reactive updates via ValueListenableBuilder

**UI Components:**
- Header showing total audio layer count and current time
- Thumbnail strip for video context
- Audio layer bars positioned according to start time and duration
- Current time indicator that moves during playback

### 3. Audio Editor Dialog

**New File:** `lib/features/audio_editor/audio_editor_dialog.dart`

**Features:**
- Edit audio layer start time with slider
- Display audio duration (read-only)
- Display calculated end time
- Visual timeline showing audio position
- Delete audio layer functionality with confirmation
- Preview audio layer position on video thumbnails

**UI Components:**
- Audio file information display
- Timeline visualization with thumbnail background
- Start time adjustment slider
- Delete button with confirmation state
- Save/Cancel actions

### 4. Main Editor Integration

**File:** `lib/features/main_editor/main_editor.dart`

**Changes:**
- Added `_onAudioLayerTap()` method to handle audio layer editing
- Updated `openAudioEditor()` to use int milliseconds
- Modified `_buildBottomNavBar()` to include AudioTimelineBar when audio layers exist
- Added imports for AudioEditorDialog and AudioTimelineBar

**Integration:**
- Audio timeline appears above bottom bar when audio layers are present
- Timeline automatically shows/hides based on audio layer presence
- Timeline updates in real-time during video playback

### 5. Audio Playback Synchronization

**File:** `lib/features/main_editor/widgets/main_editor_layers.dart`

**Changes:**
- Updated `_onVideoPlayerChanged()` to use int milliseconds
- Changed audio layer time comparisons to use milliseconds
- Updated audio player seek logic to use Duration(milliseconds: ...)

**Benefits:**
- Precise synchronization with video playback
- Smooth audio transitions
- Proper handling of overlapping audio layers

### 6. FFmpeg Export Service

**File:** `lib/features/main_editor/services/ffmpeg_export_service.dart`

**Changes:**
- Updated to use `startTime` as int milliseconds directly
- Simplified delay calculation (no need for `.inMilliseconds`)

**Benefits:**
- Cleaner code
- Consistent with new AudioLayer structure
- Maintains existing multi-audio mixing functionality

## Architecture Decisions

### 1. Multi-Layer Approach
- **Decision:** Support multiple audio layers with individual timing
- **Rationale:** Consistent with timed text/paint, professional video editing standard
- **Benefits:** Maximum flexibility, allows background music + sound effects + voiceovers

### 2. Int Milliseconds
- **Decision:** Use `int` milliseconds instead of `Duration` objects
- **Rationale:** Consistency with TimedLayer, TimedTextLayer, TimedPaintLayer
- **Benefits:** Easier calculations, more precise control, consistent API

### 3. Timeline Above Bottom Bar
- **Decision:** Show audio timeline above the bottom toolbar
- **Rationale:** Non-intrusive, contextual, easy to access
- **Benefits:** Doesn't block main editing area, appears only when needed

### 4. Reactive Timeline
- **Decision:** Use ValueListenableBuilder for real-time updates
- **Rationale:** Efficient, smooth animation, minimal rebuilds
- **Benefits:** Timeline indicator moves smoothly during playback

### 5. Visual Stacking
- **Decision:** Stack up to 3 audio layers vertically in timeline
- **Rationale:** Show multiple layers without excessive height
- **Benefits:** Compact display, clear visualization of overlaps

## User Workflow

### Adding Audio
1. User taps "Audio" button in bottom bar (video editor mode only)
2. Audio recorder modal appears
3. User records or selects audio
4. Audio layer is created at current video playback position
5. Audio timeline automatically appears above bottom bar

### Editing Audio
1. User taps on audio layer bar in timeline
2. Audio editor dialog opens
3. User adjusts start time with slider
4. Visual feedback shows audio position on timeline
5. User saves changes or deletes layer

### Playback
1. Video plays normally
2. Audio timeline shows current position with red indicator
3. Audio layers play/pause synchronized with video
4. Multiple audio layers can play simultaneously

### Export
1. User completes editing and taps "Done"
2. FFmpeg merges all audio layers with original video audio
3. Output video contains mixed audio at correct positions

## Technical Details

### Audio Layer Properties
```dart
class AudioLayer {
  final String path;           // Path to audio file
  final int duration;          // Duration in milliseconds
  final int startTime;         // Start time in milliseconds
  int get endTime;            // Calculated: startTime + duration
  bool isPlayingAtTime(int);  // Check if playing at given time
}
```

### Timeline Calculations
- Position: `(startTime / totalDuration) * screenWidth`
- Width: `(duration / totalDuration) * screenWidth`
- Current time indicator: `(currentTime / totalDuration) * screenWidth`

### Color Assignment
- 8 predefined colors: blue, green, orange, purple, teal, pink, amber, cyan
- Color index: `layerIndex % 8`
- Ensures visual distinction between layers

## Future Enhancements

Potential features for future versions:
1. Volume control per audio layer
2. Fade in/out effects
3. Audio trimming (select portion of audio file to play)
4. Mute original video audio option
5. Audio waveform visualization
6. Drag-and-drop timeline editing
7. Audio layer duplication
8. Audio effects (reverb, echo, etc.)

## Testing Recommendations

1. **Single Audio Layer:** Test basic add, edit, delete, playback
2. **Multiple Audio Layers:** Test overlapping audio, stacking display
3. **Timeline Interaction:** Test tap to edit, visual feedback
4. **Playback Sync:** Test audio starts/stops at correct times
5. **Export:** Test FFmpeg mixing with multiple audio layers
6. **Edge Cases:** Test very short/long audio, start at video end, etc.
7. **Performance:** Test with many audio layers (5+)

## Migration Notes

### Breaking Changes
- `AudioLayer.startTime` changed from `Duration` to `int`
- `AudioLayer.duration` changed from `Duration` to `int`

### Migration Code
```dart
// Old code
AudioLayer(
  path: audioPath,
  duration: Duration(seconds: 10),
  startTime: Duration(seconds: 5),
)

// New code
AudioLayer(
  path: audioPath,
  duration: 10000, // milliseconds
  startTime: 5000,  // milliseconds
)
```

## Files Created
1. `lib/features/audio_editor/widgets/audio_timeline_bar.dart` (281 lines)
2. `lib/features/audio_editor/audio_editor_dialog.dart` (378 lines)

## Files Modified
1. `lib/core/models/layers/audio_layer.dart`
2. `lib/features/main_editor/main_editor.dart`
3. `lib/features/main_editor/widgets/main_editor_layers.dart`
4. `lib/features/main_editor/services/ffmpeg_export_service.dart`

## Total Lines Changed
- Added: ~659 lines (new files)
- Modified: ~50 lines (existing files)
- Total: ~709 lines

## Conclusion

The multi-audio layer timeline implementation provides a professional, intuitive interface for managing audio in video editing. By following the established patterns from timed text and timed paint features, the implementation maintains consistency across the codebase while delivering powerful functionality to users.

