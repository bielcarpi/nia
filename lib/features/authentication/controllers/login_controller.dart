import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/utils/validator/validator.dart';

import '../views/signup_screen.dart';

class LoginController extends GetxController {
  FirebaseAuth _auth = FirebaseAuth.instance;
  Rxn<User> _firebaseUser = Rxn<User>();

  String get user => _firebaseUser.value?.email ?? "";

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  //Rx variables to observe changes
  final errorMessage = "".obs;
  final isPasswordVisible = false.obs;

  @override
  void onInit() {
    _firebaseUser.bindStream(_auth.authStateChanges()); //When the user is logged in, the _firebaseUser will be updated
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void signupClicked() {
    Get.to(SignupScreen());
  }

  void loginClicked() async {
    errorMessage.value = ""; // Clean previous errors
    AuthenticationRepository.instance.login(email, password);
  }

  void forgetPasswordClicked() {
    // TODO: go to forget password screen
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
