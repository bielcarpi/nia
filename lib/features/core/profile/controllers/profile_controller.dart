import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final RxString userProfileImage = 'https://via.placeholder.com/150'.obs;
  final RxString userName = 'Nombre Completo'.obs;

  void goToInformation() {
    // Get.to(() => UserInformationScreen());
  }

  void goToStatistics() {
    // Get.to(() => StatisticsScreen());
  }

  void goToSuscription() {
    // Get.to(() => SuscriptionScreen());
  }

  void goToQuestions() {
    // Get.to(() => QuestionsScreen());
  }

  void deleteAccount() {
    //No fem pantalla, boto per eliminar + confirmació del usuari
  }

  void signOut() {
    // Lógica per tancar la sessió
    // Get.offAll(() => LoginScreen());
  }

  @override
  void onInit() {
    super.onInit();
  }

  selectTab(BuildContext context, int index) {}
}
