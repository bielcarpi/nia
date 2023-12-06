import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecte_prmbls/features/authentication/controllers/signup_controller.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: const Center(
        child: Text('Sign up'),
      ),
    );
  }
}
