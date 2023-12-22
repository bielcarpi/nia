import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/forget_password_screen.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';

import '../../core/views/home_screen.dart';


class LoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }


  void loginClicked({required String email, required String password}) async {
    errorMessage.value = ""; // Clean previous errors
    if (await AuthenticationRepository.instance.login(email, password)) {
      Get.to(HomeScreen());
    } else {
      errorMessage.value = "Login failed";
    }
  }

  void forgetPasswordClicked() {
    // TODO: go to forget password screen
    Get.to(ForgetPasswordScreen());
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
