import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/authentication/views/forget_password_screen.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';

import '../../core/views/home_screen.dart';

class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final errorMessage = RxString("");
  final isPasswordVisible = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void loginClicked({required String email, required String password}) async {
    errorMessage.value = "";
    var success = await AuthenticationRepository.instance.login(email, password);
    if (success) {
      Get.to(HomeScreen());
      print('[SYSTEM] -> Login success');
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK");
      print('[SYSTEM] -> Login failed');
    }
  }

  void showFailedDialog(String message, String textButton) {
    Get.defaultDialog(
      title: message,
      titleStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      middleText: "The email or password is incorrect. Please try again.",
      middleTextStyle: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
      textConfirm: "OK",
      confirmTextColor: textButtonColor,
      buttonColor: buttonPrimaryColor,
      onConfirm: () {
        Get.back();
      },
    );
    emailController.clear();
    passwordController.clear();
  }


  void forgetPasswordClicked() {
    Get.to(ForgetPasswordScreen());
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
