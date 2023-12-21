import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/utils/validator/validator.dart';

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

  void loginClicked() async {
    errorMessage.value = ""; // Clean previous errors

    final email = emailController.text.trim();
    final password = passwordController.text;
    // Check if the email and password are valid
    if (!Validator.email(email)) {
      errorMessage.value = tr('auth.login.invalid_email');
      return;
    }
    if (!Validator.password(password)) {
      errorMessage.value = tr('auth.login.invalid_password');
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        errorMessage.value = tr('auth.login.user_not_found');
      } else if (e.code == 'wrong-password') {
        errorMessage.value = tr('auth.login.wrong_password');
      }
    } catch (e) {
      errorMessage.value = tr('auth.login.error');
    }
  }

  void forgetPasswordClicked() {
    // TODO: go to forget password screen
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
