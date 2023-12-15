import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/onboarding/controllers/onboarding_controller.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('OnboardingScreen'),
      ),
    );
  }
}
