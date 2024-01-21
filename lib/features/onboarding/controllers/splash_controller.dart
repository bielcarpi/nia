import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/firebase_options.dart';
import 'package:nia_flutter/repository/analytics_repository/analytics_repository.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/repository/internal_api_repository/internal_api_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class SplashController extends GetxController {
  @override
  void onInit() async {
    super.onInit();

    // Wait for firebase to initialize
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    // Initialize repositories
    Get.put(AuthenticationRepository(), permanent: true);
    Get.put(InternalAPIRepository(), permanent: true);
    Get.put(AnalyticsRepository(), permanent: true);

    // Set the initial screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offAllNamed(AppRoutes.ONBOARDING);
    });
  }
}
