import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/forget_password_screen.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';

import '../../core/views/home_screen.dart';
import '../views/signup_screen.dart';

class LoginController extends GetxController {
  FirebaseAuth _auth = FirebaseAuth.instance;
  Rxn<User> _firebaseUser = Rxn<User>();

  //String get user => _firebaseUser.value?.email ?? "";

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    //_firebaseUser.bindStream(_auth.authStateChanges()); //When the user is logged in, the _firebaseUser will be updated
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void goToSignUpScreen() {
    Get.to(SignupScreen());
  }

  void loginClicked({required String email, required String password}) async {
    errorMessage.value = ""; // Clean previous errors
    if (await AuthenticationRepository.instance.login(email, password)) {
      Get.to(HomeScreen());
    } else {
      errorMessage.value = "Login failed";
    }
  }

  void forgetPasswordClicked() {
    Get.to(ForgetPasswordScreen());
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
