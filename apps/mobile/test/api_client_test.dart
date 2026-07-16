import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nia_flutter/core/api/api_client.dart';
import 'package:nia_flutter/core/auth/app_check.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';

void main() {
  test('API client sends auth, App Check, and request correlation headers',
      () async {
    late http.Request captured;
    final client = ApiClient(
      baseUrl: Uri.parse('https://api.nia.test'),
      auth: _TokenAuthService(),
      appCheck: _StaticAppCheck(),
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode(<String, Object>{'ok': true}), 200);
      }),
    );

    await client.get('/api/v1/me/preferences');

    expect(captured.headers['authorization'], 'Bearer firebase-id-token');
    expect(captured.headers['x-firebase-appcheck'], 'app-check-token');
    expect(captured.headers['x-request-id'], startsWith('mobile-'));
    client.close();
  });

  test('API error envelope becomes a typed exception', () async {
    final client = ApiClient(
      baseUrl: Uri.parse('https://api.nia.test'),
      auth: _TokenAuthService(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode(<String, Object>{
            'error': <String, Object>{
              'code': 'rate_limited',
              'message': 'Slow down.',
              'request_id': 'request-123',
            },
          }),
          429,
        ),
      ),
    );

    await expectLater(
      client.get('/api/v1/conversations'),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'rate_limited')
            .having((error) => error.requestId, 'requestId', 'request-123'),
      ),
    );
    client.close();
  });
}

class _TokenAuthService implements AuthService {
  @override
  Stream<AuthUser?> get authStateChanges => const Stream<AuthUser?>.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> idToken() async => 'firebase-id-token';

  @override
  Future<void> signIn(
      {required String email, required String password}) async {}

  @override
  Future<void> signInToDemo() async {}

  @override
  Future<void> signOut() async {}
}

class _StaticAppCheck implements AppCheckTokenProvider {
  @override
  Future<String?> token() async => 'app-check-token';
}
