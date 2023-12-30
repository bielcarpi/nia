import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class InternalAPIRepository extends GetxController {
  static InternalAPIRepository get instance => Get.find();

  final API_URL = "https://nia-backend.oa.r.appspot.com/api";
  final SEND_AUDIO_ENDPOINT = "/audio";
  final TEXT_TO_SPEECH_ENDPOINT = "/tts";

  Future<http.Response> sendAudio(String filePath) async {
    try {
      File file = File(filePath);
      List<int> fileBytes = await file.readAsBytes();

      var response = await http.post(
        Uri.parse(API_URL + SEND_AUDIO_ENDPOINT),
        body: fileBytes,
        headers: {
          'Content-Type': 'audio/m4a',
        },
      );

      return response;
    } catch (e) {
      print('Error uploading file: $e');
      return http.Response('Error uploading file: $e', 500);
    }
  }

  Future<http.Response?> textToSpeech(String text) async {
    // TODO: Implement text to speech API on backend
    return null;
  }
}