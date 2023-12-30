import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/message_bubble/message_bubble_view.dart';
import 'package:nia_flutter/features/core/home/controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(HomeController());

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      children: [
        /*
        ListView.builder(
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final conversation = controller.conversations[index];
            return MessageBubble(
              message: conversation.content,
              isUser: conversation.isUser,
            );
          },
        ),
         */
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Obx(
              () => FloatingActionButton(
                onPressed: controller.onClickRecordButton,
                backgroundColor:
                    controller.isRecording.value ? Colors.red : Colors.blue,
                child: const Icon(Icons.mic),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
