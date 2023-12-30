import 'package:get/get.dart';
import 'package:nia_flutter/common_widgets/alerts/alerts.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';

class AuthDecisionController extends GetxController {

  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void pushSignUpScreen() {Get.offNamed(AppRoutes.SIGNUP);}
  void pushLoginScreen() {Get.offNamed(AppRoutes.LOGIN);}

/*
  Future<void> loginWithGoogleClicked() async {
    var success = await AuthenticationRepository.instance.signInWithGoogle();
    if (success) {
      Get.offNamed(AppRoutes.HOME);
    } else {
      errorMessage.value = "Login failed";
      showFailedDialog(errorMessage.value, "OK", "Login with Google failed");
      print('[SYSTEM] -> Login failed');
    }
  }
 */

  void loginWithFacebookClicked() {
  }

  void loginWithAppleClicked() {
  }

}
