import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';
import 'package:nia_flutter/features/authentication/views/login_screen.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';

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
    AuthenticationRepository.instance.firebaseAuthSignOut().then((_) {
      Get.lazyPut(()=>LoginController()); // Create a new instance of LoginController
      Get.offAll(() => LoginScreen()); // Navigate to LoginScreen
    });
  }

  @override
  void onInit() {
    super.onInit();
  }

  selectTab(BuildContext context, int index) {}
}
