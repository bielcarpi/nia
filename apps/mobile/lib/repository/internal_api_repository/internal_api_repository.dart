import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:nia_flutter/utils/logs/logs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/io.dart';

class InternalAPIRepository extends GetxController {
  static InternalAPIRepository get instance => Get.find();

  final API_URL = "wss://nia-backend.oa.r.appspot.com/api";
  final SEND_AUDIO_ENDPOINT = "/audio";
  final TEXT_TO_SPEECH_ENDPOINT = "/tts";

  IOWebSocketChannel? channel;
  AudioRecorder recorder = AudioRecorder();
  AudioPlayer player = AudioPlayer();
  bool isRecording = false;
  String? recordingPath;
  String? playingPath;

  // Initialize WebSocket connection
  Future<void> initWebSocket(Function addMessage, Function endedPlaying) async {
    channel =
        IOWebSocketChannel.connect(Uri.parse(API_URL + SEND_AUDIO_ENDPOINT));

    await channel?.ready;
    var tempDir = await getTemporaryDirectory();
    playingPath = "${tempDir.path}/received.aac";
    List<Uint8List> chunks = [];
    var tempFile = File(playingPath!);
    bool first = true;

    channel!.stream.listen(
      (data) async {
        if (data is String) {
          if (data == "END_OF_AUDIO") return;
          addMessage(data, first);
          first = false;
        } else if (data is Uint8List) {
          print('Received audio data. Chunk size: ${data.length}');
          chunks.add(data); // Receive on RAM
        }
      },
      onDone: () async {
        // Save chunks to file, then play
        if(await tempFile.exists()) {
          await tempFile.delete();
        }
        for (var chunk in chunks) {
          await tempFile.writeAsBytes(chunk, mode: FileMode.append);
        }
        await player.setFilePath(playingPath!);
        await player.play();
        player.playerStateStream.listen((event) {
          if (event.processingState == ProcessingState.completed) {
            endedPlaying();
          }
        });
      },
      onError: (error) {
        print('Error: $error');
      },
    );
  }

  // Start recording and sending audio data
  void startRecording() async {
    if (!await recorder.hasPermission()) {
      print('You must accept permission to record audio');
    }

    if (!isRecording) {
      isRecording = true;

      /*
      //TODO Implement Whisper on backend that supports PCM16 encoding
      final stream = await recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
      ));

      stream.listen((data) {
        print('Sending audio data. Chunk size: ${data.length}');
        channel!.sink.add(data);
      });
       */

      //For now, use M4A
      var tempPath = await getTemporaryDirectory();
      recordingPath = '${tempPath.path}/audio.m4a';

      await recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
          ),
          path: recordingPath!);
    }
  }

  // Stop recording
  void stopRecording() async {
    if (isRecording) {
      await recorder.stop();

      //For now, send M4A file (TODO Implement PCM16 on backend)
      print('Sending audio file: $recordingPath');
      channel!.sink.add(await File(recordingPath!).readAsBytes());

      print('Sending END_OF_AUDIO');
      channel!.sink.add("END_OF_AUDIO");

      isRecording = false;
    }
  }

  void processTextData(String text) {
    Logs.d("Received text: $text");
  }
}
