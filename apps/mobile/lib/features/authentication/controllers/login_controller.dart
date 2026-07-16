import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';


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

  void loginClicked() async {
    errorMessage.value = "";
    var success = await AuthenticationRepository.instance.login(emailController.text, passwordController.text);
    if (success) {
      Get.offNamed(AppRoutes.CORE);
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK", "Email or password is incorrect. Please try again.");
    }
  }

  void backClicked() {
    Get.offNamed(AppRoutes.AUTHDECISION);
  }

  void forgetPasswordClicked() {
    Get.offNamed(AppRoutes.FORGET_PASSWORD);
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void clearData() {
    emailController.clear();
    passwordController.clear();
  }
}
