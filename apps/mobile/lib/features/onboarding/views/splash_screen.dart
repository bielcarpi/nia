import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/onboarding/controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Force the controller to be created (if not already created)
    var splashController = controller;

    return Scaffold(
      backgroundColor: thirdColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo/nia.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
