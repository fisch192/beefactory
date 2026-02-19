import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../data/remote/api_client.dart';
import '../../data/remote/auth_api.dart';
import '../models/user.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name);
  Future<UserModel> loginWithGoogle(String idToken);
  Future<void> logout();
  bool get isLoggedIn;
  Future<UserModel?> getCurrentUser();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  UserModel? _cachedUser;

  AuthRepositoryImpl({
    required AuthApi authApi,
    required ApiClient apiClient,
    required SharedPreferences prefs,
  })  : _authApi = authApi,
        _apiClient = apiClient,
        _prefs = prefs;

  @override
  bool get isLoggedIn => _apiClient.isAuthenticated;

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _authApi.login(
        email: email,
        password: password,
      );

      final userData = response['user'] as Map<String, dynamic>? ?? response;
      final user = UserModel.fromJson(userData);
      _cachedUser = user;

      if (user.id != null) {
        await _prefs.setString(AppConstants.userIdKey, user.id!);
      }

      return user;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> register(
      String email, String password, String name) async {
    try {
      await _authApi.register(
        email: email,
        password: password,
        name: name,
      );

      // Auto-login after register
      final loginResponse = await _authApi.login(
        email: email,
        password: password,
      );

      final userData =
          loginResponse['user'] as Map<String, dynamic>? ?? loginResponse;
      final user = UserModel.fromJson(userData);
      _cachedUser = user;

      if (user.id != null) {
        await _prefs.setString(AppConstants.userIdKey, user.id!);
      }

      return user;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<UserModel> loginWithGoogle(String idToken) async {
    try {
      final response = await _authApi.loginWithGoogle(idToken: idToken);
      final userData = response['user'] as Map<String, dynamic>? ?? response;
      final user = UserModel.fromJson(userData);
      _cachedUser = user;
      if (user.id != null) {
        await _prefs.setString(AppConstants.userIdKey, user.id!);
      }
      return user;
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // Clear local state regardless
    }
    _cachedUser = null;
    await _prefs.remove(AppConstants.userIdKey);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    if (!isLoggedIn) return null;

    try {
      final response = await _authApi.getProfile();
      final userData = response['user'] as Map<String, dynamic>? ?? response;
      _cachedUser = UserModel.fromJson(userData);
      return _cachedUser;
    } catch (_) {
      return null;
    }
  }
}
