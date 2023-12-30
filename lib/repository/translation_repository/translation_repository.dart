import 'package:get/get.dart';

class TranslationRepository extends GetxController {
  static TranslationRepository get instance => Get.find();

  Future<String> translate(String srcLanguage, String destLanguage, String text) async {
    //TODO: Implement translation
    // We'll use on-device translation for now, to reduce costs
    //https://pub.dev/packages/google_mlkit_translation
    return text;
  }
}
