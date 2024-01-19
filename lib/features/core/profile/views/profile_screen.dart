import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';
import 'package:nia_flutter/features/core/profile/controllers/profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});


  @override
  Widget build(BuildContext context) {
    var controller = Get.put(ProfileController());
    String imageUrl =
        'https://static.thenounproject.com/png/3445536-200.png'; //Placeholder image
    bool imageUpdated = false;

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(top: 100),
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
                        child: Icon(Icons.camera_alt, size: 20, color: Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  controller.userName.value,
                  style: TextStyle(color: thirdColor),
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
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    // Get.to(() => InfoUserScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.bar_chart),
                  title: Text('Estadísticas'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    // Get.to(() => StadisticsScreen());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.subscriptions),
                  title: Text('Suscripciones'),
                  iconColor: primaryColor,
                  textColor: primaryColor,
                  onTap: () {
                    // Get.to(() => SubscriptionsScreen());
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
                    // _confirmSignOut(context);
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
