import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.isDemo,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isDemo;
}

abstract interface class AuthService {
  AuthUser? get currentUser;
  Stream<AuthUser?> get authStateChanges;

  Future<void> signIn({required String email, required String password});
  Future<void> signInToDemo();
  Future<String?> idToken();
  Future<void> signOut();
  Future<void> dispose();
}

class DemoAuthService implements AuthService {
  DemoAuthService({this.token});

  final String? token;
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> get authStateChanges async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await signInToDemo();
  }

  @override
  Future<void> signInToDemo() async {
    _user = const AuthUser(
      id: 'demo-user',
      email: 'demo@nia.local',
      displayName: 'Language learner',
      isDemo: true,
    );
    _controller.add(_user);
  }

  @override
  Future<String?> idToken() async => token;

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> dispose() => _controller.close();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().map(_map);

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signInToDemo() {
    throw StateError('Demo sign-in is disabled in production mode.');
  }

  @override
  Future<String?> idToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> dispose() async {}

  static AuthUser? _map(firebase.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      displayName:
          user.displayName ?? user.email?.split('@').first ?? 'Learner',
      isDemo: false,
    );
  }
}
