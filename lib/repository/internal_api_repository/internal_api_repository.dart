import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:nia_flutter/utils/logs/logs.dart';
import 'package:web_socket_channel/io.dart';

class InternalAPIRepository extends GetxController {
  static InternalAPIRepository get instance => Get.find();

  final API_URL = "https://nia-backend.oa.r.appspot.com/api";
  final SEND_AUDIO_ENDPOINT = "/audio";
  final TEXT_TO_SPEECH_ENDPOINT = "/tts";

  IOWebSocketChannel? channel;
  FlutterSoundRecorder? audioRecorder;
  FlutterSoundPlayer? audioPlayer;
  StreamController<Food> streamController = StreamController<Food>();
  bool isRecording = false;

  // Initialize WebSocket connection
  void initWebSocket(String url) {
    channel = IOWebSocketChannel.connect(Uri.parse(url));
    channel!.stream.listen(
          (data) {
        if (data is String) {
          // Handle text data
          processTextData(data);
        } else if (data is Uint8List) {
          // Handle binary audio data
          playAudioStream(data);
        }
      },
      onDone: () {
        // Handle socket closing
      },
      onError: (error) {
        // Handle error
      },
    );
  }

  // Start recording and sending audio data
  void startRecording() async {
    audioRecorder = FlutterSoundRecorder();
    await audioRecorder!.openRecorder();

    audioRecorder!.startRecorder(
      toStream: streamController.sink,
    );
    isRecording = true;

    // Listen to the stream and send data over WebSocket
    streamController.stream.listen((data) {
      if (channel != null) {
        channel!.sink.add(data);
      }
    });
  }
  // Stop recording
  void stopRecording() async {
    if (isRecording) {
      await audioRecorder!.stopRecorder();
      await audioRecorder!.closeRecorder();
      audioRecorder = null;
      isRecording = false;
    }
  }

  // Process received text data
  void processTextData(String text) {
    Logs.d("Received text: $text");
  }

  // Play audio data as it's received
  void playAudioStream(Uint8List audioData) async {
    if (audioPlayer == null) {
      audioPlayer = FlutterSoundPlayer();
      await audioPlayer!.openPlayer();
    }
    await audioPlayer!.startPlayer(fromDataBuffer: audioData);
  }

  // Clean up resources
  void dispose() {
    if (isRecording) stopRecording();
    audioPlayer?.closePlayer();
    channel?.sink.close();
  }

  Future<http.Response?> textToSpeech(String text) async {
    // TODO: Implement text to speech API on backend
    // TODO: Mainly to reproduce messages again on the chat
    return null;
  }
}