import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nia_flutter/features/authentication/views/authdecision_screen.dart';
import 'package:nia_flutter/features/core/profile/views/niaInformation.dart';
import 'package:nia_flutter/features/core/profile/views/subscription_screen.dart';
import '../../../../repository/bucket_repository/bucket_repository.dart';
import '../../../../utils/image_picker.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';
import 'package:nia_flutter/features/authentication/views/login_screen.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';


class ProfileController extends GetxController {
  final RxString userProfileImage = 'https://via.placeholder.com/150'.obs;
  final RxString userName = 'Nombre Completo'.obs;

  final picker = ImagePicker();

  Future<String?> selectImage() async {
    // Select an image from the device's gallery
    final pickedFile = await GalleryPicker.selectImage();
    if (pickedFile == null) {
      return null;
    }
    print('Image selected correctly');

    // Upload the image to Firebase Bucket
    var success = await BucketRepository.instance.uploadImage(pickedFile);

    print('Image uploaded correctly');
    return success;
  }


  void goToInformation() {
    Get.to(() => niaInformation());
  }

  void goToSubscription() {
    Get.to(() => subscriptionView());
  }

  void goToQuestions() {
    // Get.to(() => QuestionsScreen());
  }

  void deleteAccount() {
    //No fem pantalla, boto per eliminar + confirmació del usuari
  }

  void signOut() {
    AuthenticationRepository.instance.firebaseAuthSignOut().then((_) {
      Get.offAll(() => const AuthDecisionScreen());
    });
  }

  selectTab(BuildContext context, int index) {}
}
