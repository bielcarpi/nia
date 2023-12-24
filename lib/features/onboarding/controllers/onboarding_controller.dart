import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/authdecision_screen.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  int clickCount = 0;

  @override
  void onInit() {
    super.onInit();
    pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (pageController.page == 3) {
      Get.to(AuthDecisionScreen());
    }
  }

  void skipClicked() {
    Get.to(AuthDecisionScreen());
  }

  void nextClicked() {
    clickCount++;

    if (clickCount == 3) {
      Get.to(AuthDecisionScreen());
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
