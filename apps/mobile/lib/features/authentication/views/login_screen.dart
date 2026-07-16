import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            controller.backClicked();
          },
          color: buttonPrimaryColor,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(defaultSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  tr("Login"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: formSpacing),
                Text(
                  tr("Hello there! We missed you."),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: primaryColor),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email, color: transparentBlue),
                    labelText: tr("email"),
                    labelStyle: const TextStyle(color: transparentBlue),
                  ),
                ),
                const SizedBox(height: formSpacing),
                // Espacio entre campos de texto
                Obx(() {
                  return TextFormField(
                    controller: controller.passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    decoration: InputDecoration(
                      prefixIcon:
                          const Icon(Icons.lock, color: transparentBlue),
                      labelText: tr("password"),
                      labelStyle: const TextStyle(color: transparentBlue),
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
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => controller.forgetPasswordClicked(),
                    child: Text(
                      tr("Did you forget your password?"),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: formSpacing),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.loginClicked(),
                    style: ElevatedButton.styleFrom(
                      primary: buttonPrimaryColor,
                      onPrimary: thirdColor,
                      textStyle: const TextStyle(color: buttonPrimaryColor),
                      fixedSize: const Size.fromHeight(50),
                      side: const BorderSide(
                          color: buttonPrimaryColor, width: 2.0),
                    ),
                    child: Text(
                      tr("Enter"),
                      style: const TextStyle(color: thirdColor, fontSize: 18),
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
