import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
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
    } else {
      errorMessage.value = "Register failed";
    }
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

}
