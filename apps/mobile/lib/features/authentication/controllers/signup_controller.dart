import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';
import 'package:nia_flutter/utils/logs/logs.dart';

class SignupController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void registerClicked() async {
    errorMessage.value = "";
    Logs.i("hola! --> ${emailController.text} ${passwordController.text}");
    if (await AuthenticationRepository.instance.register(emailController.text, passwordController.text)) {
      Get.offNamed(AppRoutes.CORE);
    } else {
      errorMessage.value = "Register failed";
      showFailedDialog(errorMessage.value, "OK", "Email or password is incorrect. Please try again.");
      passwordController.clear();
    }
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void backClicked() {
    clearData();
    Get.offNamed(AppRoutes.AUTHDECISION);
  }

  void clearData() {
    emailController.clear();
    passwordController.clear();
  }

}
