import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig({
    required this.demoMode,
    required this.localStack,
    required this.apiBaseUrl,
    this.firebaseOptions,
    this.recaptchaSiteKey,
  });

  factory AppConfig.fromEnvironment() {
    const demoMode = bool.fromEnvironment('NIA_DEMO_MODE', defaultValue: true);
    const localStack = bool.fromEnvironment(
      'NIA_LOCAL_STACK',
      defaultValue: false,
    );
    const apiBaseUrl = String.fromEnvironment(
      'NIA_API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );

    if (demoMode) {
      return AppConfig(
        demoMode: true,
        localStack: localStack,
        apiBaseUrl: Uri.parse(apiBaseUrl),
      );
    }

    const apiKey = String.fromEnvironment('NIA_FIREBASE_API_KEY');
    const appId = String.fromEnvironment('NIA_FIREBASE_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'NIA_FIREBASE_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('NIA_FIREBASE_PROJECT_ID');
    const authDomain = String.fromEnvironment('NIA_FIREBASE_AUTH_DOMAIN');
    const recaptchaSiteKey = String.fromEnvironment(
      'NIA_FIREBASE_RECAPTCHA_SITE_KEY',
    );

    final missing = <String>[
      if (apiKey.isEmpty) 'NIA_FIREBASE_API_KEY',
      if (appId.isEmpty) 'NIA_FIREBASE_APP_ID',
      if (messagingSenderId.isEmpty) 'NIA_FIREBASE_MESSAGING_SENDER_ID',
      if (projectId.isEmpty) 'NIA_FIREBASE_PROJECT_ID',
      if (kIsWeb && recaptchaSiteKey.isEmpty) 'NIA_FIREBASE_RECAPTCHA_SITE_KEY',
    ];
    if (missing.isNotEmpty) {
      throw StateError(
        'Production mode requires these --dart-define values: '
        '${missing.join(', ')}',
      );
    }

    return AppConfig(
      demoMode: false,
      localStack: false,
      apiBaseUrl: Uri.parse(apiBaseUrl),
      recaptchaSiteKey: recaptchaSiteKey,
      firebaseOptions: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
      ),
    );
  }

  final bool demoMode;
  final bool localStack;
  final Uri apiBaseUrl;
  final FirebaseOptions? firebaseOptions;
  final String? recaptchaSiteKey;
}
