import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../repository/user_repository/user_repository.dart';

class LanguageController extends GetxController {
  RxBool changingLanguage = false.obs;
  RxString activeLanguage = Locale('en').languageCode.obs;

  Future<void> changeLanguage(String language, BuildContext context) async {
    if (changingLanguage.value) return;
    if (context.locale.languageCode == language) return;

    changingLanguage.value = true;

    final newLocale = Locale(language);
    await context.setLocale(newLocale);
    await Get.updateLocale(newLocale);

    activeLanguage.value = language;
    changingLanguage.value = false;
    //UserRepository.instance.updateLanguage(language);

    Navigator.of(context).pop();
  }
}
