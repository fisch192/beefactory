import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/errors/exceptions.dart';

class ApiClient {
  final http.Client _httpClient;
  final SharedPreferences _prefs;

  ApiClient({
    http.Client? httpClient,
    required SharedPreferences prefs,
  })  : _httpClient = httpClient ?? http.Client(),
        _prefs = prefs;

  String get baseUrl => AppConstants.apiBaseUrl;

  // ---- Token management ----

  String? get token => _prefs.getString(AppConstants.jwtTokenKey);
  String? get refreshToken => _prefs.getString(AppConstants.refreshTokenKey);

  Future<void> saveTokens(String jwt, String refresh) async {
    await _prefs.setString(AppConstants.jwtTokenKey, jwt);
    await _prefs.setString(AppConstants.refreshTokenKey, refresh);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(AppConstants.jwtTokenKey);
    await _prefs.remove(AppConstants.refreshTokenKey);
    await _prefs.remove(AppConstants.userIdKey);
  }

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
    };
    if (withAuth && token != null) {
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }
    return headers;
  }

  // ---- HTTP methods ----

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: queryParams);
    return _sendRequest(() => _httpClient.get(uri, headers: _headers(withAuth: withAuth)),
        withAuth: withAuth);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendRequest(
      () => _httpClient.post(uri, headers: _headers(withAuth: withAuth), body: jsonEncode(body)),
      withAuth: withAuth,
    );
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendRequest(
      () => _httpClient.put(uri, headers: _headers(withAuth: withAuth), body: jsonEncode(body)),
      withAuth: withAuth,
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendRequest(
        () => _httpClient.delete(uri, headers: _headers(withAuth: withAuth)),
        withAuth: withAuth);
  }

  // ---- Internal helpers ----

  Future<Map<String, dynamic>> _sendRequest(
    Future<http.Response> Function() requestFn, {
    bool withAuth = true,
    bool isRetry = false,
  }) async {
    try {
      final response = await requestFn().timeout(AppConstants.httpTimeout);

      if (response.statusCode == 401 && withAuth && !isRetry) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _sendRequest(requestFn, withAuth: withAuth, isRetry: true);
        }
        throw const AuthException('Session expired. Please log in again.');
      }

      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException('Unable to reach server');
    } on http.ClientException {
      throw const NetworkException('Connection error');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      throw ServerException('Empty response', statusCode: response.statusCode);
    }

    final body = jsonDecode(response.body);
    final data = body is Map<String, dynamic> ? body : <String, dynamic>{'data': body};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = data['message'] as String? ??
        data['error'] as String? ??
        'Unknown server error';

    if (response.statusCode == 401) {
      throw AuthException(message);
    }
    throw ServerException(message, statusCode: response.statusCode);
  }

  Future<bool> _tryRefreshToken() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return false;

    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await _httpClient.post(
        uri,
        headers: _headers(withAuth: false),
        body: jsonEncode({'refresh_token': rt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final newToken = data['token'] as String? ?? data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String? ?? rt;
        if (newToken != null) {
          await saveTokens(newToken, newRefresh);
          return true;
        }
      }
    } catch (_) {
      // Refresh failed silently
    }
    return false;
  }

  void dispose() {
    _httpClient.close();
  }
}
