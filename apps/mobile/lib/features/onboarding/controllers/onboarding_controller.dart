import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/authdecision_screen.dart';
import 'package:nia_flutter/routing/app_routes.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  int clickCount = 0;

  void skipClicked() {
    Get.offAllNamed(AppRoutes.AUTHDECISION);
  }

  void nextClicked() {
    clickCount++;

    if (clickCount == 3) {
      Get.offAllNamed(AppRoutes.AUTHDECISION);
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
