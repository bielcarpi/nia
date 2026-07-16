import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/language_controller.dart';
import '../../../../constants/colors.dart';

class LanguageScreen extends StatelessWidget {
  final LanguageController languageController = Get.put(LanguageController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('auth.language.title'), style: TextStyle(color: primaryColor)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                tr('auth.language.question'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: TextButton(
                      onPressed: () => languageController.changeLanguage('en', context),
                      child: Text(
                        'English',
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 16, color: messageBubble),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => languageController.changeLanguage('es', context),
                      child: Text(
                        'Español',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: messageBubble),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => languageController.changeLanguage('ca', context),
                      child: Text(
                        'Català',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 16, color: messageBubble),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
