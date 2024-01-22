import 'package:get/get.dart';
import 'package:nia_flutter/features/core/home/models/message.dart';
import 'package:nia_flutter/repository/internal_api_repository/internal_api_repository.dart';


class HomeController extends GetxController {
  final isRecording = false.obs;

  RxList<Message> conversation = <Message>[
    Message(content: "Hi, I'm Nia! How can I help you?", isUser: false),
  ].obs;

  void addMessage(String message, bool isUser) {
    conversation.add(Message(content: message, isUser: isUser));
  }

  void onClickRecordButton() async {
    isRecording.value = !isRecording.value;

    if (isRecording.value) {
      await InternalAPIRepository.instance.initWebSocket(addMessage);
      InternalAPIRepository.instance.startRecording();
    } else {
      InternalAPIRepository.instance.stopRecording();
    }
  }
}
