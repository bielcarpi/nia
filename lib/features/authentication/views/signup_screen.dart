import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/signup_controller.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(defaultSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () { controller.backClicked(); },
                    color: buttonPrimaryColor,
                  ),
                ),
                Text(
                  tr("Register"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: formSpacing),
                Text(
                  tr("Hello! We are glad to see you."),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: primaryColor),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: transparentBlue),
                    labelText: tr("email"),
                    labelStyle: TextStyle(color: transparentBlue),
                  ),
                ),
                SizedBox(height: formSpacing),
                Obx(() {
                  return TextFormField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: transparentBlue),
                      labelText: tr("password"),
                      labelStyle: TextStyle(color: transparentBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          controller.isPasswordVisible.value
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: transparentBlue,
                        ),
                        onPressed: controller.passwordVisibilityClicked,
                      ),
                    ),
                  );
                }),
                SizedBox(height: formSpacingRegister),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.registerClicked(),
                    style: ElevatedButton.styleFrom(
                      primary: buttonPrimaryColor,
                      onPrimary: thirdColor,
                      textStyle: const TextStyle(color: buttonPrimaryColor),
                      fixedSize: const Size.fromHeight(50),
                      side: BorderSide(color: buttonPrimaryColor, width: 2.0),
                    ),
                    child: Text(
                      tr("Sign up"),
                      style: TextStyle(color: thirdColor, fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
