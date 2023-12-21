import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/controllers/signup_controller.dart';

import '../../../constants/sizes.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(defaultSpacing),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr("auth.login.title"),
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  Text(
                    tr("Hello! We are glad to see you."),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextFormField(
                    controller: controller.emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      labelText: tr("email"),
                    ),
                  ),
                  const SizedBox(height: formSpacing),
                  Obx(() {
                    return TextFormField(
                      controller: controller.passwordController,
                      obscureText: !controller.isPasswordVisible.value,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.fingerprint),
                        labelText: tr("password"),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: controller.passwordVisibilityClicked,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: formSpacing),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => controller.registerClicked(email, password),
                      child: Text(
                        tr("Sign up"),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
