import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nia_flutter/app/nia_app.dart';
import 'package:nia_flutter/config/app_config.dart';
import 'package:nia_flutter/core/api/api_client.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/domain/models.dart';

void main() {
  group('production configuration', () {
    test('rejects a contradictory production local-stack mode', () {
      expect(
        () => AppConfig.validateModeCombination(
          demoMode: false,
          localStack: true,
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.validateModeCombination(
          demoMode: true,
          localStack: true,
        ),
        returnsNormally,
      );
    });

    test('requires an explicit non-local HTTPS API URL', () {
      expect(
        () => AppConfig.parseApiBaseUrl('', production: true),
        throwsStateError,
      );
      expect(
        () => AppConfig.parseApiBaseUrl(
          'http://api.example.com',
          production: true,
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.parseApiBaseUrl(
          'https://localhost:8080',
          production: true,
        ),
        throwsStateError,
      );
      expect(
        () => AppConfig.parseApiBaseUrl(
          'https://api.example.com/base-path',
          production: true,
        ),
        throwsStateError,
      );
      expect(
        AppConfig.parseApiBaseUrl(
          'https://api.example.com',
          production: true,
        ),
        Uri.parse('https://api.example.com'),
      );
    });

    test('offline demo keeps a credential-free localhost default', () {
      expect(
        AppConfig.parseApiBaseUrl('', production: false),
        Uri.parse('http://localhost:8080'),
      );
    });
  });

  testWidgets('bootstrap failures render an actionable screen', (tester) async {
    await tester.pumpWidget(
      NiaBootstrapErrorApp(
        error: StateError('Production NIA_API_BASE_URL must use HTTPS.'),
      ),
    );
    expect(find.text('Nia needs valid runtime configuration'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.textContaining('must use HTTPS'), findsOneWidget);
  });

  group('realtime grant contract', () {
    test('accepts a complete WebRTC response', () {
      final grant = RealtimeGrant.fromJson(
        _grantJson(
          transport: 'webrtc',
          clientSecret: <String, Object>{
            'value': 'ephemeral-secret',
            'expires_at': 1784193000,
          },
        ),
      );

      expect(grant.canUseWebRtc, isTrue);
      expect(grant.model, 'gpt-realtime-2.1');
      expect(grant.expiresAt?.isUtc, isTrue);
    });

    test('production repository rejects a valid demo transport', () async {
      final api = ApiClient(
        baseUrl: Uri.parse('https://api.example.com'),
        auth: DemoAuthService(token: 'test-token'),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode(_grantJson(transport: 'demo', clientSecret: null)),
            200,
          ),
        ),
      );
      final repository = ApiConversationRepository(api);

      await expectLater(
        repository.createSession(const TutorPreferences.defaults()),
        throwsA(
          isA<ApiException>().having(
            (error) => error.code,
            'code',
            'invalid_realtime_transport',
          ),
        ),
      );
      api.close();
    });

    test('rejects missing or contradictory session metadata', () {
      final missingRealtime = _grantJson(
        transport: 'webrtc',
        clientSecret: <String, Object>{
          'value': 'ephemeral-secret',
          'expires_at': 1784193000,
        },
      )..remove('realtime');
      expect(
        () => RealtimeGrant.fromJson(missingRealtime),
        throwsFormatException,
      );
      expect(
        () => RealtimeGrant.fromJson(
          _grantJson(transport: 'webrtc', clientSecret: null),
        ),
        throwsFormatException,
      );
      expect(
        () => RealtimeGrant.fromJson(
          _grantJson(
            transport: 'demo',
            clientSecret: <String, Object>{
              'value': 'must-not-exist',
              'expires_at': 1784193000,
            },
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => RealtimeGrant.fromJson(
          _grantJson(transport: 'demo', clientSecret: 'not-an-object'),
        ),
        throwsFormatException,
      );
    });
  });
}

Map<String, Object?> _grantJson({
  required String transport,
  required Object? clientSecret,
}) =>
    <String, Object?>{
      'conversation': <String, Object?>{
        'id': 'conv_01JNA6HF7BP6KS7X1Q43KM9N34',
        'status': 'active',
        'preferences': <String, Object?>{
          'target_language': 'es',
          'level': 'intermediate',
          'topic': 'Travel',
          'correction_style': 'gentle',
        },
        'turn_count': 0,
        'created_at': '2026-07-16T09:00:00Z',
        'updated_at': '2026-07-16T09:00:00Z',
      },
      'client_secret': clientSecret,
      'realtime': <String, Object?>{
        'transport': transport,
        'endpoint': transport == 'webrtc'
            ? 'https://api.openai.com/v1/realtime/calls'
            : 'demo://local',
        'model':
            transport == 'webrtc' ? 'gpt-realtime-2.1' : 'deterministic-demo',
      },
    };
