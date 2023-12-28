import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';

import '../../core/views/home_screen.dart';

class SignupController extends GetxController {
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

  void registerClicked({required String email, required String password}) async {
    errorMessage.value = "";
    if (await AuthenticationRepository.instance.register(email, password)) {
      Get.offNamed(AppRoutes.HOME);
      print('[SYSTEM] -> Register success');
    } else {
      errorMessage.value = "Register failed";
      showFailedDialog(errorMessage.value, "OK", "Email or password is incorrect. Please try again.");
      clearData();
      print('[SYSTEM] -> Register failed');
    }
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void backClicked() {
    Get.offNamed(AppRoutes.AUTHDECISION);
    clearData();
  }

  void clearData() {
    emailController.clear();
    passwordController.clear();
  }

}
