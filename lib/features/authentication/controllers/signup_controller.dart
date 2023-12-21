import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
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
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void createUser(String email, String password) async {
    errorMessage.value = ""; // Clean previous errors
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        errorMessage.value = tr('auth.signup.weak_password');
      } else if (e.code == 'email-already-in-use') {
        errorMessage.value = tr('auth.signup.email_already_in_use');
      }
    } catch (e) {
      errorMessage.value = tr('auth.signup.error');
    }
  }



}
