import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/profile/controllers/profile_controller.dart';
import 'package:nia_flutter/features/core/profile/views/questions_view.dart';
import 'package:nia_flutter/features/core/profile/views/subscription_screen.dart';
import 'package:nia_flutter/features/core/profile/views/language_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var controller = Get.put(ProfileController());

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 60),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () async {
                    var image = await controller.selectImage();
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(controller.userProfileImage.value),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: CircleAvatar(
                        backgroundColor: primaryColor,
                        radius: 20,
                        child: Icon(Icons.camera_alt, size: 20, color: thirdColor),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  controller.userName.value,
                  style: TextStyle(color: primaryColor),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: ListTile.divideTiles(
              context: context,
              tiles: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(tr('auth.niaInformation.title')),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    controller.goToInformation();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.subscriptions),
                  title: Text(tr('auth.subscription.title')),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    Get.to(() => subscriptionView());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.question_answer),
                  title: Text(tr('auth.questions.title')),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    Get.to(() => questionsView());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text(tr('auth.language.title')),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    Get.to(() => LanguageScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(tr('auth.login.logout')),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    controller.signOut();
                    //TODO _confirmSignOut(context);
                  },
                ),
              ],
            ).toList(),
          ),
        ),
      ],
    );
  }
}
