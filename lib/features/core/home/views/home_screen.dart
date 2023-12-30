import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/message_bubble/message_bubble_view.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/home/controllers/home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(HomeController());

    return Column(
      //backgroundColor: primaryColor,
      children: [
        Obx(() {
          if (controller.isRecording.value) {
            // Si estem en una conversa, mostrem els missatges
            return ListView.builder(
              itemCount: controller.conversations.length,
              itemBuilder: (context, index) {
                final conversation = controller.conversations[index];
                return MessageBubble(
                  message: conversation.content,
                  isUser: conversation.isUser,
                );
              },
            );
          } else {
            // Abans de comensar una conversa, mostrem això
            return const Center(
              child: Text('What do you want to talk about?',
                  style: TextStyle(color: thirdColor)),
            );
          }
        }),
        Padding(
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
      ],
    );
  }
}
