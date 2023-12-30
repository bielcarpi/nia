import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  Future<String?> startRecording() async {
    if (_isRecording) {
      throw Exception('Recording is already started.');
    }

    _isRecording = true;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/tmp.m4a';
    RecordConfig config = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 2,
    );

    await _audioRecorder.start(config, path: path);
    return path;
  }

  Future<void> stopRecording() async {
    if (!_isRecording) {
      throw Exception('Recording is not started.');
    }

    _isRecording = false;
    await _audioRecorder.stop();
  }
}
