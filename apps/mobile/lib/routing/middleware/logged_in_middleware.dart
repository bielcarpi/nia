import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/repository/authentication_repository/authentication_repository.dart';
import 'package:nia_flutter/routing/app_routes.dart';

class LoggedInMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is logged in. If so, redirect to home
    if (AuthenticationRepository.instance.isLoggedIn()) {
      return const RouteSettings(name: AppRoutes.CORE);
    }

    // User is not logged in, no redirection
    return null;
  }
}
