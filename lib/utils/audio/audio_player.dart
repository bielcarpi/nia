import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioPlayerService {
  final _audioPlayer = AudioPlayer();

  Future<void> playAudioFromResponse(http.Response response) async {
    // Create a file to store the response
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}response_audio.aac');

    // Write the response to the file
    await file.writeAsBytes(response.bodyBytes);

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
}
