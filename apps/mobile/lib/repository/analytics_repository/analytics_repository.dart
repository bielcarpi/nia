import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';
import 'package:nia_flutter/utils/logs/logs.dart';

class AnalyticsRepository {
  static AnalyticsRepository get instance => Get.find();

  Future<void> logEvent({required String name, required Map<String, dynamic> parameters}) async {
    try {
      Logs.i("Logging event: $name");
      await FirebaseAnalytics.instance
          .logEvent(name: name, parameters: parameters);
    } catch (e) {
      Logs.e(e);
    }
  }

  Future<void> logSelectContent({required String contentType, required String itemId}) async {
    try {
      Logs.i("Logging select content: $contentType, $itemId");
      await FirebaseAnalytics.instance
          .logSelectContent(contentType: contentType, itemId: itemId);
    } catch (e) {
      Logs.e(e);
    }
  }
}
