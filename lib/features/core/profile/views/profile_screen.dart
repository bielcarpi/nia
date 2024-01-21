import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/profile/controllers/profile_controller.dart';
import 'package:nia_flutter/features/core/profile/views/subscription_screen.dart';

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
                  title: Text('Información sobre Nia'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    controller.goToInformation();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.subscriptions),
                  title: Text('Subscripciones'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    Get.to(() => subscriptionView());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.question_answer),
                  title: Text('Preguntas'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    // Get.to(() => QuestionsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Eliminar mi cuenta y datos'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    // Mostrem misatge de confirmació
                    // _confirmAccountDeletion(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    // Mostrem misatge de confirmació
                    // Call the signOut function from the controller
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
