import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/constants/sizes.dart';
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
              //imagePath: 'assets/images/onboarding1.png',
            ),
            OnboardingPage(
              color: thirdColor,
              title: 'Develop your skills',
              description: 'Use the speaking features to improve your skills.',
              //imagePath: 'assets/images/onboarding2.png',
            ),
            OnboardingPage(
              color: thirdColor,
              title: 'Build your future',
              description: 'Gain confidence and improve your english skills for your future.',
              //imagePath: 'assets/images/onboarding3.png',
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

class OnboardingPage extends StatelessWidget {
  final Color color;
  final String title;
  final String description;
  //final String imagePath;

  const OnboardingPage({
    required this.color,
    required this.title,
    required this.description,
    //required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /*Image.asset(
            imagePath,
            height: 200,
          ),*/
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: textColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
