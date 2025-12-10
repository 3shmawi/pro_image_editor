import 'dart:async';

import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/statistics.dart';
import 'package:flutter/foundation.dart';

import '/core/models/layers/audio_layer.dart';

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
}
