import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    } else {
      errorMessage.value = "Login failed";
    }
  }

  void forgetPasswordClicked() {
    Get.to(ForgetPasswordScreen());
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
