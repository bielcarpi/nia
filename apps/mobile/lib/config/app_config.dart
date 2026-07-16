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
    const apiBaseUrl = String.fromEnvironment('NIA_API_BASE_URL');

    validateModeCombination(demoMode: demoMode, localStack: localStack);

    if (demoMode) {
      return AppConfig(
        demoMode: true,
        localStack: localStack,
        apiBaseUrl: parseApiBaseUrl(
          apiBaseUrl,
          production: false,
          localStack: localStack,
        ),
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
      if (apiBaseUrl.isEmpty) 'NIA_API_BASE_URL',
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
      apiBaseUrl: parseApiBaseUrl(apiBaseUrl, production: true),
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

  bool get offlineDemo => demoMode && !localStack;
  bool get production => !demoMode;

  static void validateModeCombination({
    required bool demoMode,
    required bool localStack,
  }) {
    if (localStack && !demoMode) {
      throw StateError(
        'NIA_LOCAL_STACK requires NIA_DEMO_MODE=true. Production mode cannot '
        'use local demo authentication.',
      );
    }
  }

  static Uri parseApiBaseUrl(
    String value, {
    required bool production,
    bool localStack = false,
  }) {
    final candidate = value.trim().isEmpty && !production
        ? 'http://localhost:8080'
        : value.trim();
    final uri = Uri.tryParse(candidate);
    final validHttpUri = uri != null &&
        uri.hasScheme &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.userInfo.isEmpty &&
        (uri.path.isEmpty || uri.path == '/') &&
        uri.query.isEmpty &&
        uri.fragment.isEmpty;
    if (!validHttpUri) {
      throw StateError(
        'NIA_API_BASE_URL must be an absolute HTTP(S) origin without a path, '
        'credentials, query, or fragment.',
      );
    }
    if (production && uri.scheme != 'https') {
      throw StateError('Production NIA_API_BASE_URL must use HTTPS.');
    }
    if (production &&
        (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host == '::1')) {
      throw StateError('Production NIA_API_BASE_URL cannot target localhost.');
    }
    if (localStack && production) {
      throw StateError('Local-stack and production modes cannot be combined.');
    }
    return uri;
  }
}
