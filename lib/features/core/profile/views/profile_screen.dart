import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/profile/controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var controller = Get.put(ProfileController());

    return Column(
      children: <Widget>[
        Container(
          color: thirdColor,
          width: double.infinity,
          margin: EdgeInsets.only(top: 100),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 60,
                  backgroundImage:
                      NetworkImage(controller.userProfileImage.value),
                ),
                SizedBox(height: 8),
                Text(
                  controller.userName.value,
                  style: TextStyle(color: buttonPrimaryColor),
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
                  leading: Icon(Icons.person),
                  title: Text('Mi información'),
                  iconColor: buttonPrimaryColor,
                  textColor: buttonPrimaryColor,
                  onTap: () {
                    // Get.to(() => InfoUserScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Estadísticas'),
                  iconColor: buttonPrimaryColor,
                  textColor: buttonPrimaryColor,
                  onTap: () {
                    // Get.to(() => StadisticsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.subscriptions),
                  title: Text('Suscripciones'),
                  iconColor: buttonPrimaryColor,
                  textColor: buttonPrimaryColor,
                  onTap: () {
                    // Get.to(() => SubscriptionsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.question_answer),
                  title: Text('Preguntas'),
                  iconColor: buttonPrimaryColor,
                  textColor: buttonPrimaryColor,
                  onTap: () {
                    // Get.to(() => QuestionsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever),
                  title: Text('Eliminar mi cuenta y datos'),
                  iconColor: buttonPrimaryColor,
                  textColor: buttonPrimaryColor,
                  onTap: () {
                    // Mostrem misatge de confirmació
                    // _confirmAccountDeletion(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  iconColor: buttonPrimaryColor,
                  textColor: buttonPrimaryColor,
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
