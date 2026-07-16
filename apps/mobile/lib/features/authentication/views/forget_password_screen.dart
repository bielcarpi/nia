import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/forget_password_controller.dart';

class ForgetPasswordScreen extends GetView<ForgetPasswordController> {
  const ForgetPasswordScreen({super.key});

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
                  tr("Forgot your password?"),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(color: primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: formSpacing),
                Text(
                  tr("Hello! Please complete the gaps to remember your password."),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: primaryColor),
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
                const SizedBox(height: formSpacingRegister),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.resetPasswordClicked(),
                    style: ElevatedButton.styleFrom(
                      primary: buttonPrimaryColor,
                      onPrimary: thirdColor,
                      textStyle: const TextStyle(color: buttonPrimaryColor),
                      fixedSize: const Size.fromHeight(50),
                      side: const BorderSide(color: buttonPrimaryColor, width: 2.0),
                    ),
                    child: Text(
                      tr("Reset password"),
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
