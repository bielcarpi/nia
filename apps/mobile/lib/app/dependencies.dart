import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:nia_flutter/config/app_config.dart';
import 'package:nia_flutter/core/api/api_client.dart';
import 'package:nia_flutter/core/auth/app_check.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/realtime/realtime_client.dart';

class AppDependencies {
  AppDependencies({
    required this.config,
    required this.auth,
    required this.preferences,
    required this.conversations,
    required this.realtimeClientFactory,
    this.apiClient,
  });

  static Future<AppDependencies> bootstrap(AppConfig config) async {
    if (config.demoMode && !config.localStack) {
      final repository = DemoRepository();
      return AppDependencies(
        config: config,
        auth: DemoAuthService(),
        preferences: repository,
        conversations: repository,
        realtimeClientFactory: (_) => DemoRealtimeClient(),
      );
    }

    if (config.localStack) {
      final auth = DemoAuthService(token: 'nia-local-demo');
      final api = ApiClient(
        baseUrl: config.apiBaseUrl,
        auth: auth,
        httpClient: http.Client(),
      );
      return AppDependencies(
        config: config,
        auth: auth,
        preferences: ApiPreferencesRepository(api),
        conversations: ApiConversationRepository(api),
        realtimeClientFactory: (grant) =>
            grant.canUseWebRtc ? WebRtcRealtimeClient() : DemoRealtimeClient(),
        apiClient: api,
      );
    }

    await Firebase.initializeApp(options: config.firebaseOptions);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
      providerApple: const AppleAppAttestWithDeviceCheckFallbackProvider(),
      providerWeb: ReCaptchaV3Provider(
        config.recaptchaSiteKey ?? 'native-only',
      ),
    );
    final auth = FirebaseAuthService(FirebaseAuth.instance);
    final api = ApiClient(
      baseUrl: config.apiBaseUrl,
      auth: auth,
      httpClient: http.Client(),
      appCheck: FirebaseAppCheckTokenProvider(FirebaseAppCheck.instance),
    );
    return AppDependencies(
      config: config,
      auth: auth,
      preferences: ApiPreferencesRepository(api),
      conversations: ApiConversationRepository(api),
      realtimeClientFactory: (grant) =>
          grant.canUseWebRtc ? WebRtcRealtimeClient() : DemoRealtimeClient(),
      apiClient: api,
    );
  }

  final AppConfig config;
  final AuthService auth;
  final PreferencesRepository preferences;
  final ConversationRepository conversations;
  final RealtimeClientFactory realtimeClientFactory;
  final ApiClient? apiClient;

  Future<void> dispose() async {
    apiClient?.close();
    await auth.dispose();
  }
}
