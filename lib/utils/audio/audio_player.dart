import 'dart:io';

import 'package:http/http.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  final _audioPlayer = AudioPlayer();

  Future<void> playAudioFromResponse(StreamedResponse response) async {
    // Create a file to store the response
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}response_audio.ogg');
    final fileStream = file.openWrite();

    // Write the response stream to the file
    await response.stream.pipe(fileStream);
    await fileStream.flush();
    await fileStream.close();

    // Play the audio
    try {
      await _audioPlayer.setFilePath(file.path);
      _audioPlayer.play();
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  void playAudioFromLocalFile(String s) {
    _audioPlayer.setFilePath(s);
    _audioPlayer.play();
  }
}
