import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/login_screen.dart';
import '../views/signup_screen.dart';

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

  void pushSignUpScreen() {Get.to(SignupScreen());}
  void pushLoginScreen() {Get.to(LoginScreen());}

  void loginWithGoogleClicked() {
  }

  void loginWithFacebookClicked() {
  }

  void loginWithAppleClicked() {
  }

}
