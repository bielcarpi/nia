import 'package:flutter/material.dart';
import 'package:nia_flutter/features/core/home/views/bottom_navigation_bar.dart';
import 'package:nia_flutter/features/core/profile/controllers/profile_controller.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/constants/colors.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                //color: thirdColor,
                width: double.infinity,
                margin: EdgeInsets.only(top: 100),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(controller.userProfileImage.value),
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
                        iconColor: textButtonColor,
                        textColor: textButtonColor,
                        onTap: () {
                          // Get.to(() => InfoUserScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.bar_chart),
                        title: Text('Estadísticas'),
                        iconColor: textButtonColor,
                        textColor: textButtonColor,
                        onTap: () {
                          // Get.to(() => StadisticsScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.subscriptions),
                        title: Text('Suscripciones'),
                        iconColor: textButtonColor,
                        textColor: textButtonColor,
                        onTap: () {
                          // Get.to(() => SubscriptionsScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.question_answer),
                        title: Text('Preguntas'),
                        iconColor: textButtonColor,
                        textColor: textButtonColor,
                        onTap: () {
                          // Get.to(() => QuestionsScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_forever),
                        title: Text('Eliminar mi cuenta y datos'),
                        iconColor: textButtonColor,
                        textColor: textButtonColor,
                        onTap: () {
                          // Mostrem misatge de confirmació
                          // _confirmAccountDeletion(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Cerrar sesión'),
                        iconColor: textButtonColor,
                        textColor: textButtonColor,
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
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: CustomBottomNavigationBar(
              context: context
            ),
          ),
        ],
      ),
    );
  }
}
