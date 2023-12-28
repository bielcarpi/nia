import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/repository/api_repository/api_repository.dart';
import 'package:nia_flutter/utils/audio/audio_player.dart';
import 'package:nia_flutter/utils/audio/audio_recorder.dart';
import 'package:nia_flutter/utils/logs/logs.dart';

class HomeController extends GetxController {
  final isRecording = false.obs;
  String? filePath;
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayerService();

  @override
  void onInit() {
    super.onInit();

    _audioRecorder.init();
  }

  @override
  void onClose() {
    _audioRecorder.dispose();
    super.onClose();
  }

  selectTab(BuildContext context, int index) {}

  void onClickRecordButton() async {
    isRecording.value = !isRecording.value;

    if (isRecording.value) {
      filePath = await _audioRecorder.startRecording();
    } else {
      _audioRecorder.stopRecording();

      if (filePath != null) {
        _audioPlayer.playAudioFromLocalFile(filePath!);

        await Future.delayed(const Duration(seconds: 3));
        Logs.i("Sending audio to server...");

        var response = await APIRepository.instance.sendAudioToServer(filePath!);
        if (response != null) {
          _audioPlayer.playAudioFromResponse(response);
        }
      }
    }
  }
}
