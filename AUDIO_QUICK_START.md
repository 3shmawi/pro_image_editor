# Audio Feature - Quick Start Guide

## 5-Minute Setup

### 1. Enable Audio Tool
```dart
ProImageEditor.video(
  videoController,
  configs: ProImageEditorConfigs(
    mainEditor: MainEditorConfigs(
      tools: [
        SubEditorMode.audio,  // Add this line
      ],
    ),
  ),
);
```

### 2. Handle Export
```dart
callbacks: ProImageEditorCallbacks(
  onImageEditingComplete: (bytes) async {
    final file = File('output.mp4');
    await file.writeAsBytes(bytes);
  },
),
```

### 3. Done!
Users can now:
- Tap **Audio** button to add audio
- See audio in timeline
- Tap audio to edit
- Export video with mixed audio

---

## User Workflow

```
1. Load Video
   ↓
2. Tap "Audio" Button
   ↓
3. Record/Select Audio
   ↓
4. Audio Added to Timeline
   ↓
5. (Optional) Tap Audio to Edit
   ↓
6. Tap "Done" to Export
   ↓
7. Progress Dialog Shows
   ↓
8. Video Exported with Audio
```

---

## Key Features

✅ **Multiple Audio Layers** - Add unlimited audio tracks  
✅ **Visual Timeline** - See all audio in one view  
✅ **Precise Timing** - Millisecond-accurate positioning  
✅ **Real-time Playback** - Audio syncs with video  
✅ **Progress Tracking** - Visual export feedback  
✅ **Easy Editing** - Tap to edit any layer  

---

## Common Tasks

### Add Background Music
```dart
final music = AudioLayer(
  path: '/path/to/music.mp3',
  duration: 30000,  // 30 seconds
  startTime: 0,     // Start at beginning
);
editorState.addLayer(music);
```

### Add Sound Effect
```dart
final effect = AudioLayer(
  path: '/path/to/effect.wav',
  duration: 2000,   // 2 seconds
  startTime: 5000,  // At 5 seconds
);
editorState.addLayer(effect);
```

### Get All Audio Layers
```dart
final audioLayers = activeLayers
    .whereType<AudioLayer>()
    .toList();
```

### Remove Audio Layer
```dart
removeLayer(audioLayer);
```

---

## Timeline UI

```
┌─────────────────────────────────────┐
│ Audio Layers (3)         00:05.2    │
├─────────────────────────────────────┤
│ [Thumbnails]                        │
├─────────────────────────────────────┤
│ [Blue]──────                        │ ← Music
│     [Green]────────────             │ ← Voiceover
│         [Orange]───────             │ ← Effect
│                │                    │
│                └─ Current time      │
└─────────────────────────────────────┘
```

**Tap any audio bar to edit it!**

---

## Export Progress

```
┌─────────────────────────────┐
│    [Video Icon]             │
│    Exporting Video          │
│  Mixing audio with video... │
│  ████████████░░░░░░░░░░░   │
│  67%          Please wait...│
│         [Spinner]           │
└─────────────────────────────┘
```

---

## Troubleshooting

### No Progress Dialog?
- Check audio layers exist
- Verify video controller is set
- Run in debug mode

### Audio Not Playing?
- Check audio file exists
- Verify audio format supported
- Check device volume

### Export Failed?
- Check debug logs
- Verify FFmpeg is available
- Check storage space

---

## Debug Mode

```bash
flutter run --debug
```

Look for logs:
```
Starting audio export...
FFmpeg progress: 25.5%
FFmpeg progress: 50.2%
FFmpeg progress: 100.0%
Export complete!
```

---

## Need More Help?

📖 **Full Documentation:** `AUDIO_FEATURE_DOCUMENTATION.md`  
🐛 **Troubleshooting:** See documentation Section 7  
💡 **Examples:** See documentation Section 8  
🔧 **API Reference:** See documentation Section 6  

---

## Quick Reference

| Task | Code |
|------|------|
| Enable audio | `tools: [SubEditorMode.audio]` |
| Add layer | `addLayer(AudioLayer(...))` |
| Get layers | `whereType<AudioLayer>()` |
| Remove layer | `removeLayer(layer)` |
| Check playing | `layer.isPlayingAtTime(time)` |

---

**That's it! You're ready to use the audio feature! 🎉**

