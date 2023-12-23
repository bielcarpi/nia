import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';

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
      Get.to(HomeScreen());
      print('[SYSTEM] -> Register success');
    } else {
      errorMessage.value = "Register failed";
      showFailedDialog(errorMessage.value, "OK");
      print('[SYSTEM] -> Register failed');
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

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

}
