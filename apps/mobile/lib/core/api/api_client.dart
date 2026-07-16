import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nia_flutter/core/auth/app_check.dart';
import 'package:nia_flutter/core/auth/auth_service.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.requestId,
  });

  final String code;
  final String message;
  final int? statusCode;
  final String? requestId;

  bool get retryable =>
      statusCode == null || statusCode == 408 || (statusCode ?? 0) >= 500;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required Uri baseUrl,
    required AuthService auth,
    http.Client? httpClient,
    AppCheckTokenProvider appCheck = const NoAppCheckTokenProvider(),
    this.timeout = const Duration(seconds: 15),
  })  : _baseUrl = baseUrl,
        _auth = auth,
        _appCheck = appCheck,
        _http = httpClient ?? http.Client();

  final Uri _baseUrl;
  final AuthService _auth;
  final AppCheckTokenProvider _appCheck;
  final http.Client _http;
  final Duration timeout;
  int _requestCounter = 0;

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<Object?> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Object?> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Object?> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<void> delete(String path) async {
    await _send('DELETE', path);
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) async {
    final uri = _baseUrl.resolve(path).replace(queryParameters: query);
    final token = await _auth.idToken();
    final appCheckToken = await _appCheck.token();
    final requestId = 'mobile-${DateTime.now().microsecondsSinceEpoch}-'
        '${_requestCounter++}';
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Request-ID': requestId,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      if (appCheckToken != null && appCheckToken.isNotEmpty)
        'X-Firebase-AppCheck': appCheckToken,
    };
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    try {
      final streamed = await _http.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamed);
      final decoded = _decode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _exceptionFrom(response.statusCode, decoded, requestId);
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        code: 'request_timeout',
        message: 'The request took too long. Check your connection and retry.',
      );
    } on http.ClientException {
      throw const ApiException(
        code: 'network_unavailable',
        message: 'Nia could not reach the server. Check your connection.',
      );
    }
  }

  static Object? _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body) as Object?;
    } on FormatException {
      return null;
    }
  }

  static ApiException _exceptionFrom(
    int statusCode,
    Object? decoded,
    String fallbackRequestId,
  ) {
    final root = asJsonMap(decoded);
    final error = asJsonMap(root?['error']);
    return ApiException(
      code: error?['code'] as String? ?? 'http_error',
      message: error?['message'] as String? ??
          'The server could not complete this request.',
      statusCode: statusCode,
      requestId: error?['request_id'] as String? ?? fallbackRequestId,
    );
  }

  void close() => _http.close();
}

Map<String, Object?>? asJsonMap(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return null;
}
