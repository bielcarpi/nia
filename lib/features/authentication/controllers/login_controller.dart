import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';
import 'package:nia_flutter/utils/logs/logs.dart';


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
      Get.offNamed(AppRoutes.HOME);
      Logs.i('[SYSTEM] -> Login success');
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK", "Email or password is incorrect. Please try again.");
      clearData();
      Logs.i('[SYSTEM] -> Login failed');
    }
  }

  void backClicked() {
    Get.offNamed(AppRoutes.AUTHDECISION);
    clearData();
  }

  void forgetPasswordClicked() {
    Get.offNamed(AppRoutes.FORGET_PASSWORD);
    clearData();
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void clearData() {
    emailController.clear();
    passwordController.clear();
  }
}
