import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorder {
  FlutterSoundRecorder? _audioRecorder;
  bool _isRecorderInitialized = false;

  Future<void> init() async {
    _audioRecorder = FlutterSoundRecorder();

    await _audioRecorder!.openRecorder();
    _isRecorderInitialized = true;
  }

  Future<String?> startRecording() async {
    if (!_isRecorderInitialized) return null;

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/temp_recording.aac';
    await _audioRecorder!.startRecorder(toFile: path);
    return path;
  }

  Future<void> stopRecording() async {
    await _audioRecorder!.stopRecorder();
  }

  void dispose() {
    if (_audioRecorder != null) {
      _audioRecorder!.closeRecorder();
      _audioRecorder = null;
    }
    _isRecorderInitialized = false;
  }
}
