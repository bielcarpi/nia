import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/core/controllers/home_controller.dart';
import 'package:nia_flutter/features/profile/controllers/profile_controller.dart';
import 'package:nia_flutter/features/timeline/controllers/timeline_controller.dart';
import '../../../common_widgets/bottomNavigationBar/bottomNavigationBar.dart';
import '../../../common_widgets/messageBubble/messageBubble.dart';
import '../../../constants/colors.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());
    Get.put(ProfileController());
    Get.put(TimelineController());

    return Scaffold(
      backgroundColor: primaryColor,
      body: Obx(() {
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
            child: Text('What do you want to talk about?', style: TextStyle(color: thirdColor)),
          );
        }
      }),
      bottomNavigationBar: CustomBottomNavigationBar(
        context: context,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100), // Añade padding solo en la parte inferior
        child: Obx(
              () => FloatingActionButton(
            onPressed: controller.onClickRecordButton,
            backgroundColor: controller.isRecording.value ? Colors.red : Colors.blue,
            child: const Icon(Icons.mic),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
