import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecte_prmbls/features/authentication/controllers/forget_password_controller.dart';

class ForgetPasswordScreen extends GetView<ForgetPasswordController> {
  const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('ForgetPasswordScreen'),
      ),
    );
  }
}