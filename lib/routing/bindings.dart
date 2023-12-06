import 'package:get/get.dart';
import 'package:projecte_prmbls/features/authentication/controllers/forget_password_controller.dart';
import 'package:projecte_prmbls/features/authentication/controllers/login_controller.dart';
import 'package:projecte_prmbls/features/authentication/controllers/signup_controller.dart';
import 'package:projecte_prmbls/features/core/controllers/home_controller.dart';
import 'package:projecte_prmbls/features/onboarding/controllers/onboarding_controller.dart';
import 'package:projecte_prmbls/features/onboarding/controllers/splash_controller.dart';

class SplashScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
  }
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.create<SignupController>(() => SignupController());
  }
}

class ForgetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgetPasswordController>(() => ForgetPasswordController());
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
