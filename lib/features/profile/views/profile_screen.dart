import 'package:flutter/material.dart';
import 'package:nia_flutter/features/profile/controllers/profile_controller.dart';
import '../../../common_widgets/bottomNavigationBar/bottomNavigationBar.dart';
import 'package:get/get.dart';

class ProfileScreen extends GetView<ProfileController> {
  final ProfileController profileController = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              Container(
                color: Colors.blue,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 40, // Tamaño de la imagen de perfil
                        backgroundImage: NetworkImage(profileController.userProfileImage.value), // La URL de la imagen
                      ),
                      SizedBox(height: 8),
                      Text(
                        profileController.userName.value, // Nombre o correo de l'usuario
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children: ListTile.divideTiles( // Esta es una manera fácil de obtener líneas divisorias.
                    context: context,
                    tiles: [
                      ListTile(
                        leading: Icon(Icons.person),
                        title: Text('Mi información'),
                        onTap: () {
                          // Get.to(() => InfoUserScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.bar_chart),
                        title: Text('Estadísticas'),
                        onTap: () {
                          // Get.to(() => StadisticsScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.subscriptions),
                        title: Text('Suscripciones'),
                        onTap: () {
                          // Get.to(() => SubscriptionsScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.question_answer),
                        title: Text('Preguntas'),
                        onTap: () {
                          // Get.to(() => QuestionsScreen());
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.delete_forever),
                        title: Text('Eliminar mi cuenta y datos'),
                        onTap: () {
                          // Mostrem misatge de confirmació
                          // _confirmAccountDeletion(context);
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Cerrar sesión'),
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
