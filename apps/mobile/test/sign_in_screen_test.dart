import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nia_flutter/app/dependencies.dart';
import 'package:nia_flutter/config/app_config.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';
import 'package:nia_flutter/core/theme/nia_theme.dart';
import 'package:nia_flutter/data/repositories.dart';
import 'package:nia_flutter/realtime/realtime_client.dart';
import 'package:nia_flutter/ui/sign_in_screen.dart';

void main() {
  testWidgets('existing users can sign in and request a reset', (tester) async {
    final auth = _RecordingAuthService();
    final repository = DemoRepository();
    final dependencies = AppDependencies(
      config: AppConfig(
        demoMode: false,
        localStack: false,
        apiBaseUrl: Uri.parse('https://api.example.com'),
      ),
      auth: auth,
      preferences: repository,
      conversations: repository,
      realtimeClientFactory: (_) => DemoRealtimeClient(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: SignInScreen(dependencies: dependencies),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'learner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'sixsix',
    );
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Sign in'),
    );
    await tester.pumpAndSettle();
    expect(auth.lastSignInEmail, 'learner@example.com');

    await _tapVisible(tester, find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(auth.lastResetEmail, 'learner@example.com');
    expect(find.textContaining('Password reset email sent'), findsOneWidget);
  });

  testWidgets('new accounts retain a stronger creation-only password rule',
      (tester) async {
    final auth = _RecordingAuthService();
    final repository = DemoRepository();
    final dependencies = AppDependencies(
      config: AppConfig(
        demoMode: false,
        localStack: false,
        apiBaseUrl: Uri.parse('https://api.example.com'),
      ),
      auth: auth,
      preferences: repository,
      conversations: repository,
      realtimeClientFactory: (_) => DemoRealtimeClient(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildNiaTheme(),
        home: SignInScreen(dependencies: dependencies),
      ),
    );
    await _tapVisible(tester, find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'short',
    );
    await _tapVisible(
      tester,
      find.widgetWithText(FilledButton, 'Create account'),
    );
    await tester.pump();
    expect(find.textContaining('Use at least 8 characters'), findsOneWidget);
    expect(auth.createdEmail, isNull);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

class _RecordingAuthService implements AuthService {
  String? lastSignInEmail;
  String? lastResetEmail;
  String? createdEmail;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream<AuthUser?>.empty();

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> createAccount({
    required String email,
    required String password,
  }) async {
    createdEmail = email;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> idToken() async => null;

  @override
  Future<void> sendPasswordReset(String email) async {
    lastResetEmail = email;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    lastSignInEmail = email;
  }

  @override
  Future<void> signInToDemo() async {}

  @override
  Future<void> signOut() async {}
}
