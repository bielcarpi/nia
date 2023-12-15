import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/forget_password_screen.dart';
import 'package:nia_flutter/features/authentication/views/login_screen.dart';
import 'package:nia_flutter/features/authentication/views/signup_screen.dart';
import 'package:nia_flutter/features/core/views/home_screen.dart';
import 'package:nia_flutter/features/onboarding/views/onboarding_screen.dart';
import 'package:nia_flutter/features/onboarding/views/splash_screen.dart';
import 'package:nia_flutter/routing/bindings.dart';
import 'package:nia_flutter/routing/middleware/auth_middleware.dart';

class AppRoutes {
  static const SPLASH = '/';
  static const ONBOARDING = '/onboarding';
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const FORGET_PASSWORD = '/forgetPassword';
  static const HOME = '/home';

  static final routes = [
    GetPage(
      name: SPLASH,
      page: () => const SplashScreen(),
      binding: SplashScreenBinding(),
    ),
    GetPage(
      name: ONBOARDING,
      page: () => const OnboardingScreen(),
      binding: OnboardingBinding(),
    ),
    GetPage(
      name: LOGIN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: SIGNUP,
      page: () => const SignupScreen(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: FORGET_PASSWORD,
      page: () => const ForgetPasswordScreen(),
      binding: ForgetPasswordBinding(),
    ),
    GetPage(
      name: HOME,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
