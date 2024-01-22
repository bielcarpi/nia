import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';

class AuthDecisionController extends GetxController {
  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  void pushSignUpScreen() {
    Get.offNamed(AppRoutes.SIGNUP);
  }

  void pushLoginScreen() {
    Get.offNamed(AppRoutes.LOGIN);
  }

  Future<void> loginWithGoogleClicked() async {
    var success =
        await AuthenticationRepository.instance.signInWithGoogle(Get.context!);
    if (success) {
      Get.offNamed(AppRoutes.CORE);
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK", "Login with Google failed");
    }
  }

  void loginWithFacebookClicked() async {
    var success = await AuthenticationRepository.instance
        .signInWithFacebook(Get.context!);
    if (success) {
      Get.offNamed(AppRoutes.CORE);
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK", "Login with Facebook failed");
    }
  }

  void loginWithAppleClicked() async {
    var success =
        await AuthenticationRepository.instance.signInWithApple(Get.context!);
    if (success) {
      Get.offNamed(AppRoutes.CORE);
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK", "Login with apple failed");
    }
  }
}
