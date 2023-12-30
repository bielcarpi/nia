import 'package:get/get.dart';
import 'package:nia_flutter/features/authentication/views/authdecision_screen.dart';
import 'package:nia_flutter/features/authentication/views/forget_password_screen.dart';
import 'package:nia_flutter/features/authentication/views/login_screen.dart';
import 'package:nia_flutter/features/authentication/views/signup_screen.dart';
import 'package:nia_flutter/features/core/core/views/core_screen.dart';
import 'package:nia_flutter/features/core/home/views/home_screen.dart';
import 'package:nia_flutter/features/onboarding/views/onboarding_screen.dart';
import 'package:nia_flutter/features/onboarding/views/splash_screen.dart';
import 'package:nia_flutter/routing/bindings.dart';
import 'package:nia_flutter/routing/middleware/auth_middleware.dart';
import 'package:nia_flutter/routing/middleware/logged_in_middleware.dart';

class AppRoutes {
  static const SPLASH = '/';
  static const ONBOARDING = '/onboarding';
  static const AUTHDECISION = '/authdecision';
  static const LOGIN = '/login';
  static const SIGNUP = '/signup';
  static const FORGET_PASSWORD = '/forgetPassword';
  static const CORE = '/core';

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
      middlewares: [LoggedInMiddleware()],
    ),
    GetPage(
      name: AUTHDECISION,
      page: () => const AuthDecisionScreen(),
      binding: AuthDecisionBinding(),
      middlewares: [LoggedInMiddleware()],
    ),
    GetPage(
      name: LOGIN,
      page: () => const LoginScreen(),
      binding: LoginBinding(),
      middlewares: [LoggedInMiddleware()],
    ),
    GetPage(
      name: SIGNUP,
      page: () => const SignupScreen(),
      binding: SignUpBinding(),
      middlewares: [LoggedInMiddleware()],
    ),
    GetPage(
      name: FORGET_PASSWORD,
      page: () => const ForgetPasswordScreen(),
      binding: ForgetPasswordBinding(),
      middlewares: [LoggedInMiddleware()],
    ),
    GetPage(
      name: CORE,
      page: () => const CoreScreen(),
      binding: CoreBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
