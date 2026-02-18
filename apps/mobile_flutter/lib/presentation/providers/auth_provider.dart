import 'package:flutter/foundation.dart';

import '../../core/errors/failures.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _error;

  AuthProvider(this._authRepository) {
    _initialize();
  }

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoggedIn => _state == AuthState.authenticated;
  bool get isGuest => _state == AuthState.unauthenticated;

  Future<void> _initialize() async {
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _error = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      _user = await _authRepository.register(email, password, name);
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on Failure catch (e) {
      _error = e.message;
      _state = AuthState.error;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    _user = null;
    _state = AuthState.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
