import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecte_prmbls/utils/validator/validator.dart';

class LoginController extends GetxController {
  //TextField controllers to get data from TextFields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    // TODO: Check if the user is logged in. If so, go to HOME
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void loginClicked() async {
    errorMessage.value = ""; // Clean previous errors

    // Check if the email and password are valid
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!Validator.email(email)) {
      errorMessage.value = tr('auth.login.invalid_email');
      return;
    }
    if (!Validator.password(password)) {
      errorMessage.value = tr('auth.login.invalid_password');
      return;
    }

    // TODO attempt to login with email and password
  }

  void forgetPasswordClicked() {
    // TODO go to forget password screen
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
