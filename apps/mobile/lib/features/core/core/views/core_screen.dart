import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/core/controllers/core_controller.dart';
import 'package:nia_flutter/features/core/home/views/home_screen.dart';
import 'package:nia_flutter/features/core/profile/views/profile_screen.dart';
import 'package:nia_flutter/features/core/timeline/views/timeline_screen.dart';

class CoreScreen extends GetView<CoreController> {
  const CoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NIA', style: TextStyle(color: primaryColor)),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.currentIndex.value == 0) {
          return const ProfileScreen();
        } else if (controller.currentIndex.value == 1) {
          return HomeScreen();
        } else {
          return const TimelineScreen();
        }
      }),
      bottomNavigationBar: Obx( () =>
        BottomNavigationBar(
          backgroundColor: primaryColor,
          unselectedItemColor: thirdColor,
          selectedItemColor: selectedIcon,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat),
              label: 'Timeline',
            ),
          ],
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeIndex,
        ),
      ),
    );
  }
}
