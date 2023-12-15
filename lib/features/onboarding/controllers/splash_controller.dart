import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/firebase_options.dart';
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

    Future.delayed(const Duration(milliseconds: 1500), () {
      Get.offAllNamed(AppRoutes.LOGIN);
    });
  }
}
