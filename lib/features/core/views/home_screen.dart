import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/core/controllers/home_controller.dart';
import '../../../common_widgets/bottomNavigationBar/bottomNavigationBar.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    Get.put(HomeController());

    return Scaffold(
      appBar: AppBar(
        title: Text('What do you want to talk about?'),
      ),
      body: Center(
        // Aquí va el chat que s'anira creant
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: 1, // Index para Home
        controller: controller, // Passem el controller ja que utilitzem GetView<HomeController
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aquí hem d'activar el micro per parlar amb NIA
        },
        child: Icon(Icons.mic),
        backgroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}