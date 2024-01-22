import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nia_flutter/features/authentication/views/authdecision_screen.dart';
import 'package:nia_flutter/features/core/profile/views/niaInformation.dart';
import 'package:nia_flutter/features/core/profile/views/subscription_screen.dart';
import '../../../../repository/bucket_repository/bucket_repository.dart';
import '../../../../utils/image_picker.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import '../views/language_screen.dart';
import '../views/questions_view.dart';


class ProfileController extends GetxController {
  final RxString userProfileImage = RxString('');
  final RxString userName = RxString('');
  final RxString userEmail = RxString('');

  final picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  void loadUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userName.value = user.displayName ?? 'Nombre Completo';
      userEmail.value = user.email ?? '';
      userProfileImage.value = user.photoURL ?? 'https://via.placeholder.com/150';
    }
  }


  Future<void> selectImage() async {
    // Select an image from the device's gallery
    final pickedFile = await GalleryPicker.selectImage();
    if (pickedFile == null) {
      return;
    }
    print('Image selected correctly');

    // Upload the image to Firebase Bucket
    var success = await BucketRepository.instance.uploadImage(pickedFile);
    if (success != null) {
      updateUserProfileImage(success);
    }
    print('Image uploaded correctly');
  }

  Future<void> updateUserProfileImage(String newImageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.updatePhotoURL(newImageUrl);
      userProfileImage.value = newImageUrl;
    }
  }


  void goToInformation() {
    Get.to(() => niaInformation());
  }

  void goToSubscription() {
    Get.to(() => subscriptionView());
  }

  void goToQuestions() {
    Get.to(() => questionsView());
  }

  void goToChangeLanguage() {
    Get.to(() => LanguageScreen());
  }

  void signOut() async {
    await AuthenticationRepository.instance.signOut();
    Get.offAll(() => const AuthDecisionScreen());
  }

  selectTab(BuildContext context, int index) {}
}
