import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecte_prmbls/features/authentication/controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('LoginScreen'),
      ),
    );
  }
}
