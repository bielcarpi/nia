import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/controllers/authdecision_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/forget_password_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/signup_controller.dart';
import 'package:nia_flutter/features/core/core/controllers/core_controller.dart';
import 'package:nia_flutter/features/onboarding/controllers/onboarding_controller.dart';
import 'package:nia_flutter/features/onboarding/controllers/splash_controller.dart';

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

class AuthDecisionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthDecisionController>(() => AuthDecisionController());
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
    Get.lazyPut<SignupController>(() => SignupController());
  }
}

class ForgetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgetPasswordController>(() => ForgetPasswordController());
  }
}

class CoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CoreController>(() => CoreController());
  }
}