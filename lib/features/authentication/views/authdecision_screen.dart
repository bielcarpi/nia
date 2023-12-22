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
    Get.put(AuthDecisionController());

    return Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: SvgPicture.asset(
                        "assets/social_icons/Apple.svg",
                        height: 50,
                      ),
                      onPressed: () async {
                        //TODO: Handle Apple login
                      },
                      label: SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: SvgPicture.asset(
                        "assets/social_icons/google.svg",
                        height: 50,
                      ),
                      onPressed: () async {
                        //TODO: Handle Google login
                      },
                      label: SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: SvgPicture.asset(
                        "assets/social_icons/facebook.svg",
                        height: 50,
                      ),
                      onPressed: () async {
                        //TODO: Handle Facebook login
                      },
                      label: SizedBox.shrink(),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 20),
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
                  SizedBox(width: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
