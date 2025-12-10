import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Controller for the audio recorder.
class AudioRecorderController extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();
  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _isRecording = false;
  bool _isPaused = false;
  String? _path;

  /// The current duration of the recording.
  Duration get duration => _duration;

  /// Whether the recorder is currently recording.
  bool get isRecording => _isRecording;

  /// Whether the recorder is currently paused.
  bool get isPaused => _isPaused;

  /// The path to the recorded file.
  String? get path => _path;

  /// Starts the recording.
  Future<void> start() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final location = await getTemporaryDirectory();
        final name = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _path = '${location.path}/$name';

        await _audioRecorder.start(const RecordConfig(), path: _path!);
        _isRecording = true;
        _isPaused = false;
        _duration = Duration.zero;
        _startTimer();
        notifyListeners();
      } else {
        // Request permission
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw Exception('Microphone permission not granted');
        }
        // Try again
        await start();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error starting recording: $e');
      }
      rethrow;
    }
  }

  /// Stops the recording.
  Future<String?> stop() async {
    _timer?.cancel();
    _isRecording = false;
    _isPaused = false;
    final path = await _audioRecorder.stop();
    notifyListeners();
    return path;
  }

  /// Pauses the recording.
  Future<void> pause() async {
    await _audioRecorder.pause();
    _timer?.cancel();
    _isPaused = true;
    notifyListeners();
  }

  /// Resumes the recording.
  Future<void> resume() async {
    await _audioRecorder.resume();
    _startTimer();
    _isPaused = false;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _duration += const Duration(milliseconds: 100);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
