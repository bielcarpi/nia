import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/authentication/controllers/authdecision_controller.dart';

class AuthDecisionScreen extends GetView<AuthDecisionController> {
  const AuthDecisionScreen({super.key});

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
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: thirdColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr("to Nia!"),
                  style: const TextStyle(
                    fontSize: 30,
                    color: thirdColor,
                  ),
                ),
                const SizedBox(height: 100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customSocialButton(
                      false,
                        "assets/images/social_icons/apple.svg", () =>
                        controller.loginWithAppleClicked()
                    ),
                    const SizedBox(width: 20),
                    customSocialButton(
                      true,
                        "assets/images/social_icons/google.png", () =>
                        controller.loginWithGoogleClicked()
                    ),
                    const SizedBox(width: 20),
                    customSocialButton(
                        false,
                        "assets/images/social_icons/facebook.svg", () =>
                        controller.loginWithFacebookClicked()
                    ),
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

  Widget customSocialButton(bool isPng, String iconPath, VoidCallback onPressed) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Center(
          child: isPng ?
          Image.asset(
            iconPath,
            height: 60,
          ) :
          SvgPicture.asset(
            iconPath,
            height: 60,
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
