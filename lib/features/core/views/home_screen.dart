import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/core/controllers/home_controller.dart';
import 'package:nia_flutter/features/profile/controllers/profile_controller.dart';
import 'package:nia_flutter/features/timeline/controllers/timeline_controller.dart';

import '../../../common_widgets/bottomNavigationBar/bottomNavigationBar.dart';
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
      appBar: AppBar(
        title: const Text('What do you want to talk about?'),
      ),
      body: const Center(
        child: Text('Home Screen'),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
          context:
              context // Passem el controller ja que utilitzem GetView<HomeController
          ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          onPressed: () {
            controller.onClickRecordButton();
          },
          backgroundColor: controller.isRecording.value ? Colors.red : Colors.blue,
          child: const Icon(Icons.mic),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
