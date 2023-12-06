import 'package:get/get.dart';
import 'package:projecte_prmbls/routing/app_routes.dart';

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
