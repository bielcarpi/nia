import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/forget_password_controller.dart';

class ForgetPasswordScreen extends GetView<ForgetPasswordController> {
  const ForgetPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(defaultSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        Get.back();
                      },
                      color: buttonPrimaryColor,
                    ),
                    Text(
                      tr("Forgot your password?"),
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                  ],
                ),
                Text(
                  tr("Hello! Please complete the gaps to remember your password."),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: formSpacing),
                TextFormField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email),
                    labelText: tr("email"),
                  ),
                ),
                const SizedBox(height: formSpacingRegister),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => controller.rememberPasswordClicked(
                      email: controller.emailController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: buttonPrimaryColor,
                      onPrimary: thirdColor,
                      textStyle: const TextStyle(color: buttonPrimaryColor),
                      fixedSize: const Size.fromHeight(50),
                      side: BorderSide(color: buttonPrimaryColor, width: 2.0),
                    ),
                    child: Text(
                      tr("Remember me"),
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