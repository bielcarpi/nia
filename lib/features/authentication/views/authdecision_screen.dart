import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/sizes.dart';
import 'package:nia_flutter/features/authentication/controllers/authdecision_controller.dart';

class AuthDecisionScreen extends GetView<AuthDecisionController> {
  const AuthDecisionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: EdgeInsets.only(bottom: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        icon: Center(
                          child: SvgPicture.asset(
                            "assets/images/social_icons/apple.svg",
                            height: 50,
                          ),
                        ),
                        onPressed: () async {
                          // TODO: Handle Apple login
                        },
                        label: SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: TextButton.icon(
                        icon: Center(
                          child: SvgPicture.asset(
                            "assets/images/social_icons/google.svg",
                            height: 50,
                          ),
                        ),
                        onPressed: () async {
                          // TODO: Handle Google login
                        },
                        label: SizedBox.shrink(),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: TextButton.icon(
                        icon: Center(
                          child: SvgPicture.asset(
                            "assets/images/social_icons/facebook.svg",
                            height: 50,
                          ),
                        ),
                        onPressed: () async {
                          // TODO: Handle Facebook login
                        },
                        label: SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.pushSignUpScreen();
                        },
                        child: Text('Register'),
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          controller.pushLoginScreen();
                        },
                        child: Text('Login'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}