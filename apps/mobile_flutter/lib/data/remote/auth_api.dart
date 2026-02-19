import 'api_client.dart';

class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    return _client.post(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'name': name,
      },
      withAuth: false,
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      withAuth: false,
    );

    // Persist tokens from login response
    final token = response['token'] as String? ??
        response['access_token'] as String? ??
        '';
    final refreshToken = response['refresh_token'] as String? ?? '';
    if (token.isNotEmpty) {
      await _client.saveTokens(token, refreshToken);
    }

    return response;
  }

  Future<Map<String, dynamic>> refresh() async {
    return _client.post(
      '/auth/refresh',
      body: {'refresh_token': _client.refreshToken},
      withAuth: false,
    );
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout');
    } catch (_) {
      // Even if server call fails, clear local tokens
    }
    await _client.clearTokens();
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _client.get('/auth/me');
  }

  Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final response = await _client.post(
      '/auth/google',
      body: {'id_token': idToken},
      withAuth: false,
    );
    final token = response['token'] as String? ??
        response['access_token'] as String? ??
        '';
    final refreshToken = response['refresh_token'] as String? ?? '';
    if (token.isNotEmpty) {
      await _client.saveTokens(token, refreshToken);
    }
    return response;
  }
}
