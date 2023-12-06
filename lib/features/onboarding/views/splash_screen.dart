import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecte_prmbls/constants/colors.dart';
import 'package:projecte_prmbls/features/onboarding/controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Center(
        child: Image.asset(
          'assets/images/logo/logo.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
