import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';

class SignupController extends GetxController {
  Rxn<User> _firebaseUser = Rxn<User>();

  String get user => _firebaseUser.value?.email ?? "";

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

  void registerClicked(String email, String password) async {
    errorMessage.value = ""; // Clean previous errors
    AuthenticationRepository.instance.register(email, password);
  }

  void passwordVisibilityClicked() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

}
