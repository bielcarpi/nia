import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/onboardings/onboardings.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/onboarding/controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: controller.pageController,
          children: const [
            OnboardingPage(
              color: thirdColor,
              title: 'Welcome to Nia',
              description: 'Nia is a social media app that allows you to improve your english.',
              contentColor: primaryColor,
              imagePath: 'assets/images/onboardings/onboarding1.png',
            ),
            OnboardingPage(
              color: thirdColor,
              title: 'Develop your skills',
              description: 'Use the speaking features to improve your skills.',
              contentColor: primaryColor,
              imagePath: 'assets/images/onboardings/onboarding2.png',
            ),
            OnboardingPage(
              color: thirdColor,
              title: 'Build your future',
              description: 'Gain confidence and improve your english skills for your future.',
              contentColor: primaryColor,
              imagePath: 'assets/images/onboardings/onboarding3.png',
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {controller.skipClicked();},
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () {controller.nextClicked();},
              child: const Text('Next'),
              style: TextButton.styleFrom(
                backgroundColor: buttonPrimaryColor,
                primary: thirdColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              )
            ),
          ],
        ),
      ),
    );
  }
}



