import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/authentication/controllers/authdecision_controller.dart';

class AuthDecisionScreen extends GetView<AuthDecisionController> {
  const AuthDecisionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.only(bottom: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  tr("Welcome"),
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(color: thirdColor),
                ),
                const SizedBox(height: 20),
                Text(
                  tr("to Nia!"),
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(color: thirdColor),
                ),
                const SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customSocialButton("assets/images/social_icons/apple.svg", () {
                      // TODO: Handle Apple login
                    }),
                    const SizedBox(width: 20),
                    customSocialButton("assets/images/social_icons/google.svg", () {
                      // TODO: Handle Google login
                    }),
                    const SizedBox(width: 20),
                    customSocialButton("assets/images/social_icons/facebook.svg", () {
                      // TODO: Handle Facebook login
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customRegisterButton('Register', () {
                      controller.pushSignUpScreen();
                    }),
                    const SizedBox(width: 20),
                    customLoginButton('Login', () {
                      controller.pushLoginScreen();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget customSocialButton(String iconPath, VoidCallback onPressed) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Center(
          child: SvgPicture.asset(
            iconPath,
            height: 50,
          ),
        ),
        label: const SizedBox.shrink(),
      ),
    );
  }

  Widget customLoginButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          primary: thirdColor,
          onPrimary: textColor,
          textStyle: const TextStyle(color: buttonPrimaryColor),
          fixedSize: const Size.fromHeight(50),
          side: BorderSide(color: thirdColor, width: 2.0),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontSize: 16),
        ),
      ),
    );
  }

  Widget customRegisterButton(String label, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          primary: buttonPrimaryColor,
          onPrimary: textButtonColor,
          textStyle: const TextStyle(color: buttonPrimaryColor),
          fixedSize: const Size.fromHeight(50),
          side: BorderSide(color: thirdColor, width: 2.0),
        ),
        child: Text(
          label,
          style: TextStyle(color: thirdColor, fontSize: 16),
        ),
      ),
    );
  }

}
