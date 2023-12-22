import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/authdecision_controller.dart';

class AuthDecisionScreen extends GetView<AuthDecisionController> {
  const AuthDecisionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    Get.put(AuthDecisionController());

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {controller.pushLoginScreen();},
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {controller.pushSignUpScreen();},
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}