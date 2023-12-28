import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/controllers/forget_password_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/signup_controller.dart';
import 'package:nia_flutter/features/core/controllers/home_controller.dart';
import 'package:nia_flutter/features/onboarding/controllers/onboarding_controller.dart';
import 'package:nia_flutter/features/onboarding/controllers/splash_controller.dart';
import '../features/authentication/controllers/authdecision_controller.dart';

class SplashScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
    print("[SYSTEM]-> SplashController created");
  }
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
    print("[SYSTEM]-> OnboardingController created");
  }
}

class AuthDecisionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthDecisionController>(() => AuthDecisionController());
    print("[SYSTEM]-> AuthDecisionController created");
  }
}

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
    print("[SYSTEM]-> LoginController created");
  }
}

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.create<SignupController>(() => SignupController());
    print("[SYSTEM]-> SignupController created");
  }
}

class ForgetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgetPasswordController>(() => ForgetPasswordController());
    print("[SYSTEM]-> ForgetPasswordController created");
  }
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    print("[SYSTEM]-> HomeController created");
  }
}
