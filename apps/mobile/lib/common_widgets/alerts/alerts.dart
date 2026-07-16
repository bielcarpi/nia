
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:nia_flutter/constants/colors.dart';

Future<void> showFailedDialog(String message, String textButton, String alertMessage) {
  return Get.defaultDialog(
    title: message,
    titleStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: textColor,
    ),
    middleText: alertMessage,
    middleTextStyle: const TextStyle(
      fontSize: 16,
      color: textColor,
    ),
    textConfirm: "OK",
    confirmTextColor: textButtonColor,
    buttonColor: buttonPrimaryColor,
    onConfirm: () {
      Get.back();
    },
  );
}