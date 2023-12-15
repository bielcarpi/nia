import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({Key? key}) : super(key: key);

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
              Text(
                tr("auth.login.title"),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              Text(
                tr("auth.login.description"),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextFormField(
                controller: controller.emailController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email),
                  labelText: tr("auth.login.email"),
                  hintText: tr("auth.login.email_hint"),
                ),
              ),
              const SizedBox(height: formSpacing),
              Obx(() {
                return TextFormField(
                  controller: controller.passwordController,
                  obscureText: !controller.isPasswordVisible.value,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.fingerprint),
                    labelText: tr("auth.login.password"),
                    hintText: tr("auth.login.password_hint"),
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
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => controller.forgetPasswordClicked(),
                  child: Text(tr("auth.login.forgot_password"),
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              const SizedBox(height: formSpacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.loginClicked(),
                  child: Text(
                    tr("auth.login.login").toUpperCase(),
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
