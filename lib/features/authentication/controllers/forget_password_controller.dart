import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';
import 'package:nia_flutter/utils/validator/validator.dart';

class ForgetPasswordController extends GetxController {
  final emailController = TextEditingController();
  final errorMessage = "".obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  void resetPasswordClicked() async {
    errorMessage.value = "";
    if(!Validator.email(emailController.text)) {
      showFailedDialog("Invalid email", "OK", "Please enter a valid email");
      return;
    }

    AuthenticationRepository.instance.sendPasswordResetEmail(emailController.text);
    await showFailedDialog("Email sent", "OK", "Please check your email to reset your password");
    Get.offNamed(AppRoutes.LOGIN);
  }

  void backClicked() {
    Get.offNamed(AppRoutes.LOGIN);
  }

}
