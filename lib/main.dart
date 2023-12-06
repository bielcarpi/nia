import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:projecte_prmbls/features/onboarding/views/splash_screen.dart';
import 'package:projecte_prmbls/routing/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'X',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      getPages: AppRoutes.routes,
      defaultTransition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 120),
      home: const SplashScreen(),
    );
  }
}
