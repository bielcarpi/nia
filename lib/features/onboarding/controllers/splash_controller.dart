import 'package:get/get.dart';
import 'package:nia_flutter/routing/app_routes.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offAllNamed(AppRoutes.LOGIN);
    });
  }

  void hola() {
    print("hola");
  }
}
