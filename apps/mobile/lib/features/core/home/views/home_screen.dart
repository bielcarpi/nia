import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:nia_flutter/features/core/home/controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  // Scroll controller for the ListView
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(HomeController());

    // Scroll to the bottom of the list when a new message is added
    ever(controller.conversation, (_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Obx(
            () => ListView.builder(
              controller: _scrollController,
              itemCount: controller.conversation.length,
              itemBuilder: (context, index) {
                final bubble = controller.conversation[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                  ),
                  child: BubbleSpecialThree(
                    text: bubble.content,
                    color: bubble.isUser ? Colors.grey.shade200 : Colors.blue,
                    isSender: bubble.isUser,
                    textStyle: TextStyle(
                      color: bubble.isUser ? Colors.black : Colors.white,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Obx(
              () => FloatingActionButton(
                onPressed: controller.onClickRecordButton,
                backgroundColor:
                    controller.isRecording.value ? Colors.red : Colors.blue,
                child: controller.isPlaying.value
                    ? LoadingAnimationWidget.fallingDot(
                        color: Colors.white,
                        size: 40)
                    : const Icon(Icons.mic),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
