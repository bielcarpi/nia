import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/authdecision_screen.dart';

class OnboardingController extends GetxController {
  final PageController pageController = PageController();

  @override
  void onInit() {
    super.onInit();
  }

  void skipClicked() {
    Get.to(AuthDecisionScreen());
  }

  void nextClicked() {
    // Iterate the onboarding screen
    pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }
}
