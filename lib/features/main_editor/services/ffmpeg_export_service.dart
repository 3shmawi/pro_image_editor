import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '/core/models/layers/audio_layer.dart';
import '/core/models/layers/video_bubble_layer.dart';

enum VideoBubbleCorner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// Service to handle FFmpeg operations.
class FfmpegExportService {
  /// Merges audio layers into a video.
  ///
  /// This method supports three video input sources (in priority order):
  /// 1. [videoFilePath] - Direct file path (e.g., from native rendering)
  /// 2. [videoUrl] - Network URL to download
  /// 3. [videoAssetPath] - Asset path to load
  ///
  /// [audioLayers] is the list of audio layers to merge with their timing.
  /// [outputPath] is the required path where the output video will be saved.
  /// [onProgress] is an optional callback that receives progress updates (0.0 to 1.0).
  /// [videoDurationMs] is the total video duration in milliseconds for progress calculation.
  /// [keepOriginalAudio] whether to keep the original video audio (default: false).
  ///
  /// Returns the path to the output video if successful, otherwise null.
  Future<String?> mergeAudioIntoVideo({
    required String inputVideoPath,
    required String outputPath,
    required List<AudioLayer> audioLayers,
    void Function(double progress)? onProgress,
    int? videoDurationMs,
    bool keepOriginalAudio = false,
  }) async {
    if (audioLayers.isEmpty) return inputVideoPath;

    // Check if video has original audio
    bool hasOriginalAudio = false;
    try {
      final probeSession = await FFprobeKit.execute(
        '-v error -select_streams a:0 -show_entries stream=codec_type '
        '-of default=noprint_wrappers=1:nokey=1 "$inputVideoPath"',
      );
      final probeOutput = await probeSession.getOutput();
      hasOriginalAudio = probeOutput != null && probeOutput.trim().isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to probe audio: $e');
      }
    }

    // Build FFmpeg command
    final StringBuffer command = StringBuffer();

    // Input video [0]
    command.write('-i "$inputVideoPath" ');

    // Input audio files [1]...[N]
    for (var layer in audioLayers) {
      command.write('-i "${layer.path}" ');
    }

    // Filter complex for delaying + mixing audio
    command.write('-filter_complex "');

    // Delay audio streams (each layer starts at its startTime in ms)
    for (int i = 0; i < audioLayers.length; i++) {
      final layer = audioLayers[i];
      final delay = layer.startTime; // in milliseconds
      command.write('[${i + 1}:a]adelay=${delay}:all=1[a${i + 1}];');
    }

    final bool mixWithOriginal = keepOriginalAudio && hasOriginalAudio;

    if (mixWithOriginal) {
      // Mix original audio [0:a] + all delayed layers [a1]...[aN]
      // Example:
      // [1:a]adelay=... [a1];[2:a]adelay=... [a2];[0:a][a1][a2]amix=inputs=3[aout]
      command.write('[0:a]');
      for (int i = 0; i < audioLayers.length; i++) {
        command.write('[a${i + 1}]');
      }
      final totalInputs = audioLayers.length + 1; // original + layers
      command.write(
        'amix=inputs=$totalInputs:duration=longest:dropout_transition=2[aout]" ',
      );
    } else {
      // Current behavior: use ONLY our custom delayed layers (no original audio)
      if (audioLayers.length > 1) {
        for (int i = 0; i < audioLayers.length; i++) {
          command.write('[a${i + 1}]');
        }
        command.write(
          'amix=inputs=${audioLayers.length}:duration=longest:dropout_transition=2[aout]" ',
        );
      } else {
        // Single audio layer → just pass it through as [aout]
        command.write('[a1]anull[aout]" ');
      }
    }

    // Map video (from 0:v) and our new mixed audio ([aout])
    command.write('-map 0:v -map "[aout]" ');
    command.write('-c:v copy -c:a aac -b:a 192k -y "$outputPath"');

    if (kDebugMode) {
      print('FFmpeg command: ${command.toString()}');
      print('Video duration: $videoDurationMs ms');
      print('Audio layers: ${audioLayers.length}');
      print('keepOriginalAudio: $keepOriginalAudio');
      print('hasOriginalAudio: $hasOriginalAudio');
    }

    // Progress callback
    if (onProgress != null && videoDurationMs != null && videoDurationMs > 0) {
      if (kDebugMode) {
        print('Setting up progress callback...');
      }

      onProgress(0.01);

      FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
        final timeInMs = statistics.getTime();
        if (timeInMs > 0) {
          final progress = (timeInMs / videoDurationMs).clamp(0.0, 1.0);
          if (kDebugMode) {
            print(
              'FFmpeg progress: ${(progress * 100).toStringAsFixed(1)}% (time: $timeInMs ms)',
            );
          }
          onProgress(progress);
        }
      });
    }

    if (kDebugMode) {
      print('Executing FFmpeg command...');
    }

    final session = await FFmpegKit.execute(command.toString());
    final returnCode = await session.getReturnCode();

    if (kDebugMode) {
      print('FFmpeg execution completed with return code: $returnCode');
    }

    // Disable statistics callback after execution
    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback(null);
      if (kDebugMode) {
        print('Disabled statistics callback');
      }
    }

    if (ReturnCode.isSuccess(returnCode)) {
      if (onProgress != null) {
        onProgress(1.0);
      }
      return outputPath;
    } else {
      if (kDebugMode) {
        print('FFmpeg failed with return code: $returnCode');
        print('Logs: ${await session.getLogsAsString()}');
      }
      return null;
    }
  }

  ///test video bubble
  Future<String?> addVideoBubbleToVideo({
    required String inputVideoPath, // الفيديو الأساسي
    required String bubbleVideoPath, // فيديو الشخص اللي بيشرح (bubble)
    String? outputPath,
    VideoBubbleCorner corner = VideoBubbleCorner.bottomRight,
    double bubbleScale = 0.25, // نسبة حجم البابل من عرض الفيديو
    int margin = 40, // مسافة من الحواف بالبكسل
  }) async {
    final output = outputPath ??
        '${(await getTemporaryDirectory()).path}/bubble_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // 1) نشوف لو الفيديو الأساسي فيه صوت
    bool hasOriginalAudio = false;
    try {
      final probeSession = await FFprobeKit.execute(
        '-v error -select_streams a:0 -show_entries stream=codec_type '
        '-of default=noprint_wrappers=1:nokey=1 "$inputVideoPath"',
      );
      final probeOutput = await probeSession.getOutput();
      hasOriginalAudio = probeOutput != null && probeOutput.trim().isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to probe main audio: $e');
      }
    }

    // 2) نشوف لو فيديو البابل فيه صوت
    bool hasBubbleAudio = false;
    try {
      final probeSession = await FFprobeKit.execute(
        '-v error -select_streams a:0 -show_entries stream=codec_type '
        '-of default=noprint_wrappers=1:nokey=1 "$bubbleVideoPath"',
      );
      final probeOutput = await probeSession.getOutput();
      hasBubbleAudio = probeOutput != null && probeOutput.trim().isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to probe bubble audio: $e');
      }
    }

    // 3) تحديد مكان البابل
    late final String overlayExpr;
    switch (corner) {
      case VideoBubbleCorner.topLeft:
        overlayExpr = '$margin:$margin';
        break;
      case VideoBubbleCorner.topRight:
        overlayExpr = 'main_w-overlay_w-$margin:$margin';
        break;
      case VideoBubbleCorner.bottomLeft:
        overlayExpr = '$margin:main_h-overlay_h-$margin';
        break;
      case VideoBubbleCorner.bottomRight:
      default:
        overlayExpr = 'main_w-overlay_w-$margin:main_h-overlay_h-$margin';
        break;
    }

    final StringBuffer command = StringBuffer();

    // input 0: main video
    // input 1: bubble video
    command.write('-i "$inputVideoPath" -i "$bubbleVideoPath" ');

    // -------- filter_complex --------
    final StringBuffer fc = StringBuffer();

    // أولاً: الفيديو → scale + overlay → [vout]
    fc.write('[1:v]scale=iw*$bubbleScale:-1[bubv];'
        '[0:v][bubv]overlay=$overlayExpr[vout];');

    // ثانياً: الصوت
    final bool hasAnyAudio = hasOriginalAudio || hasBubbleAudio;

    if (hasOriginalAudio && hasBubbleAudio) {
      // امكس صوت المين + صوت البابل
      // normalize=1 عشان الصوت مايعلاش قوي لما نجمع streamين
      fc.write(
          '[0:a][1:a]amix=inputs=2:duration=longest:dropout_transition=2:normalize=1[aout]');
    } else if (hasOriginalAudio) {
      // بس صوت الفيديو الأساسي
      fc.write('[0:a]anull[aout]');
    } else if (hasBubbleAudio) {
      // بس صوت البابل
      fc.write('[1:a]anull[aout]');
    } else {
      // مفيش صوت خالص → لا نضيف جزء صوتي في الفلتر
    }

    command.write('-filter_complex "${fc.toString()}" ');

    // 4) map الفيديو
    command.write('-map "[vout]" ');

    // 5) map الصوت لو موجود
    if (hasAnyAudio) {
      command.write('-map "[aout]" -c:a aac -b:a 192k ');
    }

    // 6) لازم re-encode للفيديو عشان overlay
    command.write('-c:v libx264 -preset veryfast -crf 23 -y "$output"');

    if (kDebugMode) {
      print('FFmpeg bubble command: $command');
    }

    final session = await FFmpegKit.execute(command.toString());
    final returnCode = await session.getReturnCode();

    if (kDebugMode) {
      print('FFmpeg bubble execution completed with return code: $returnCode');
      print('Logs: ${await session.getLogsAsString()}');
    }

    if (ReturnCode.isSuccess(returnCode)) {
      return output;
    } else {
      return inputVideoPath;
    }
  }

  /// Merges video bubble layers into the main video with timing support.
  ///
  /// [inputVideoPath] - Path to the main video
  /// [outputPath] - Optional output path
  /// [videoBubbleLayers] - List of video bubble layers to merge
  /// [onProgress] - Optional progress callback
  /// [videoDurationMs] - Total video duration for progress calculation
  ///
  /// Returns the path to the output video if successful, otherwise null.
  Future<String?> mergeVideoBubblesIntoVideo({
    required String inputVideoPath,
    required List<VideoBubbleLayer> videoBubbleLayers,
    String? outputPath,
    void Function(double progress)? onProgress,
    int? videoDurationMs,
  }) async {
    if (videoBubbleLayers.isEmpty) return inputVideoPath;

    final output = outputPath ??
        '${(await getTemporaryDirectory()).path}/bubbles_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // For multiple bubbles, we need to chain them
    String currentInput = inputVideoPath;

    for (int i = 0; i < videoBubbleLayers.length; i++) {
      final layer = videoBubbleLayers[i];
      final isLast = i == videoBubbleLayers.length - 1;
      final tempOutput = isLast
          ? output
          : '${(await getTemporaryDirectory()).path}/bubble_temp_$i.mp4';

      if (kDebugMode) {
        print('Processing bubble ${i + 1}/${videoBubbleLayers.length}');
        print('Start time: ${layer.startTime}ms');
        print('Duration: ${layer.duration}ms');
      }

      // Use the existing addVideoBubbleToVideo but with timing
      final result = await _addVideoBubbleWithTiming(
        inputVideoPath: currentInput,
        bubbleVideoPath: layer.path,
        outputPath: tempOutput,
        corner: layer.corner,
        bubbleScale: layer.bubbleScale,
        margin: layer.margin,
        startTime: layer.startTime,
        bubbleDuration: layer.duration,
        onProgress: onProgress != null && isLast
            ? (progress) {
                // Scale progress for this bubble
                final overallProgress =
                    (i + progress) / videoBubbleLayers.length;
                onProgress(overallProgress);
              }
            : null,
        videoDurationMs: videoDurationMs,
      );

      if (result == null) {
        if (kDebugMode) {
          print('Failed to add bubble ${i + 1}');
        }
        return null;
      }

      // Clean up intermediate file if not the first input
      if (currentInput != inputVideoPath) {
        try {
          await File(currentInput).delete();
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete temp file: $e');
          }
        }
      }

      currentInput = result;
    }

    return currentInput;
  }

  /// Internal method to add a single video bubble with timing support.
  Future<String?> _addVideoBubbleWithTiming({
    required String inputVideoPath,
    required String bubbleVideoPath,
    required String outputPath,
    required VideoBubbleCorner corner,
    required double bubbleScale,
    required int margin,
    required int startTime,
    required int bubbleDuration,
    void Function(double progress)? onProgress,
    int? videoDurationMs,
  }) async {
    // Check for audio in both videos
    bool hasOriginalAudio = false;
    try {
      final probeSession = await FFprobeKit.execute(
        '-v error -select_streams a:0 -show_entries stream=codec_type '
        '-of default=noprint_wrappers=1:nokey=1 "$inputVideoPath"',
      );
      final probeOutput = await probeSession.getOutput();
      hasOriginalAudio = probeOutput != null && probeOutput.trim().isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to probe main audio: $e');
      }
    }

    bool hasBubbleAudio = false;
    try {
      final probeSession = await FFprobeKit.execute(
        '-v error -select_streams a:0 -show_entries stream=codec_type '
        '-of default=noprint_wrappers=1:nokey=1 "$bubbleVideoPath"',
      );
      final probeOutput = await probeSession.getOutput();
      hasBubbleAudio = probeOutput != null && probeOutput.trim().isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to probe bubble audio: $e');
      }
    }

    // Determine overlay position
    late final String overlayExpr;
    switch (corner) {
      case VideoBubbleCorner.topLeft:
        overlayExpr = '$margin:$margin';
        break;
      case VideoBubbleCorner.topRight:
        overlayExpr = 'main_w-overlay_w-$margin:$margin';
        break;
      case VideoBubbleCorner.bottomLeft:
        overlayExpr = '$margin:main_h-overlay_h-$margin';
        break;
      case VideoBubbleCorner.bottomRight:
      default:
        overlayExpr = 'main_w-overlay_w-$margin:main_h-overlay_h-$margin';
        break;
    }

    final StringBuffer command = StringBuffer();

    // Input videos
    command.write('-i "$inputVideoPath" -i "$bubbleVideoPath" ');

    // Filter complex
    final StringBuffer fc = StringBuffer();

    // Convert startTime to seconds for FFmpeg
    final startTimeSec = startTime / 1000.0;
    final endTimeSec = (startTime + bubbleDuration) / 1000.0;

    // Scale the bubble video and apply timing
    // Use setpts to delay the bubble video start
    fc.write('[1:v]scale=iw*$bubbleScale:-1,');
    fc.write('setpts=PTS+$startTimeSec/TB[bubv];');

    // Overlay with enable condition to show only during the specified time range
    fc.write('[0:v][bubv]overlay=$overlayExpr:');
    fc.write('enable=\'between(t,$startTimeSec,$endTimeSec)\'[vout];');

    // Handle audio
    final bool hasAnyAudio = hasOriginalAudio || hasBubbleAudio;

    if (hasOriginalAudio && hasBubbleAudio) {
      // Mix both audio streams with delay for bubble audio
      fc.write('[1:a]adelay=${startTime}|${startTime}[buba];');
      fc.write(
          '[0:a][buba]amix=inputs=2:duration=longest:dropout_transition=2:normalize=1[aout]');
    } else if (hasOriginalAudio) {
      fc.write('[0:a]anull[aout]');
    } else if (hasBubbleAudio) {
      fc.write('[1:a]adelay=${startTime}|${startTime}[aout]');
    }

    command.write('-filter_complex "${fc.toString()}" ');

    // Map outputs
    command.write('-map "[vout]" ');
    if (hasAnyAudio) {
      command.write('-map "[aout]" -c:a aac -b:a 192k ');
    }

    // Video encoding
    command.write('-c:v libx264 -preset veryfast -crf 23 -y "$outputPath"');

    if (kDebugMode) {
      print('FFmpeg bubble with timing command: $command');
    }

    // Progress callback
    if (onProgress != null && videoDurationMs != null && videoDurationMs > 0) {
      onProgress(0.01);
      FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
        final timeInMs = statistics.getTime();
        if (timeInMs > 0) {
          final progress = (timeInMs / videoDurationMs).clamp(0.0, 1.0);
          onProgress(progress);
        }
      });
    }

    final session = await FFmpegKit.execute(command.toString());
    final returnCode = await session.getReturnCode();

    // Disable statistics callback
    if (onProgress != null) {
      FFmpegKitConfig.enableStatisticsCallback(null);
    }

    if (kDebugMode) {
      print('FFmpeg bubble execution completed with return code: $returnCode');
      if (!ReturnCode.isSuccess(returnCode)) {
        print('Logs: ${await session.getLogsAsString()}');
      }
    }

    if (ReturnCode.isSuccess(returnCode)) {
      if (onProgress != null) {
        onProgress(1.0);
      }
      return outputPath;
    } else {
      return null;
    }
  }
}
