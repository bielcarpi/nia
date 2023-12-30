import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/controllers/forget_password_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/login_controller.dart';
import 'package:nia_flutter/features/authentication/controllers/signup_controller.dart';
import 'package:nia_flutter/features/core/home/controllers/home_controller.dart';
import 'package:nia_flutter/features/onboarding/controllers/onboarding_controller.dart';
import 'package:nia_flutter/features/onboarding/controllers/splash_controller.dart';
import 'package:nia_flutter/features/core/profile/controllers/profile_controller.dart';
import 'package:nia_flutter/features/core/timeline/controllers/timeline_controller.dart';
import '../features/authentication/controllers/authdecision_controller.dart';

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

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
     Get.lazyPut<ProfileController>(() => ProfileController());
  }
}

class TimelineBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TimelineController>(() => TimelineController());
  }
}