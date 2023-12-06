import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() async {
    super.onInit();
    await Future.delayed(const Duration(milliseconds: 1500), () {
      //Get.offAllNamed('/onboarding');
    });
  }
}
