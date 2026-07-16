import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:nia_flutter/core/api/api_client.dart';

abstract interface class AppCheckTokenProvider {
  Future<String?> token();
}

class NoAppCheckTokenProvider implements AppCheckTokenProvider {
  const NoAppCheckTokenProvider();

  @override
  Future<String?> token() async => null;
}

class FirebaseAppCheckTokenProvider implements AppCheckTokenProvider {
  const FirebaseAppCheckTokenProvider(this._appCheck);
  final FirebaseAppCheck _appCheck;

  @override
  Future<String?> token() async {
    final token = await _appCheck.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        code: 'app_attestation_failed',
        message: 'This device could not be verified. Please restart Nia.',
      );
    }
    return token;
  }
}
