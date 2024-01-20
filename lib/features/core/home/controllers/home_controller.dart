import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/message_bubble/message.dart';
import 'package:nia_flutter/repository/internal_api_repository/internal_api_repository.dart';
import 'package:nia_flutter/utils/audio/audio_player.dart';
import 'package:nia_flutter/utils/audio/audio_recorder.dart';


class HomeController extends GetxController {
  final isRecording = false.obs;
  String? filePath;
  final _audioRecorder = AudioRecorderService();
  final _audioPlayer = AudioPlayerService();
  //var conversations = <Message>[].obs; // Llista on estaràn tots els missatges

  //Per fer la prova
  var conversations = [
    Message(content: "Hi, How are you?", isUser: true),
    Message(content: "I'm good, thanks!", isUser: false),
    Message(content: "Can we speak in English?", isUser: true),
    Message(content: "Yes! What do you want to talk about?", isUser: false),
  ].obs;

  selectTab(BuildContext context, int index) {}

  void onClickRecordButton() async {
    isRecording.value = !isRecording.value;

    if (isRecording.value) {
      InternalAPIRepository.instance.initWebSocket();
      InternalAPIRepository.instance.startRecording();
    } else {
      InternalAPIRepository.instance.stopRecording();
    }
  }
}
