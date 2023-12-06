import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // TODO: Check if user is logged in
    /*
    if (false) {
      // User is not logged in, redirect to login
      return const RouteSettings(name: Routing.LOGIN);
    }
     */

    // User is logged in, no redirection
    return null;
  }
}
