import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/routing/app_routes.dart';

class ForgetPasswordController extends GetxController {
  final emailController = TextEditingController();

  final errorMessage = RxString("");

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  void rememberPasswordClicked({required String email}) async {
    errorMessage.value = "";
  }

  void backClicked() {
    Get.offNamed(AppRoutes.LOGIN);
  }

}
