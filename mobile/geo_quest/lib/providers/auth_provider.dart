import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.login(email, password);
      _user = User.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _authService.register(email, password, name);
      _user = User.fromJson(data['user']);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadProfile() async {
    try {
      _user = await _authService.getProfile();
      notifyListeners();
    } catch (_) {
      // Token expired or invalid
      await logout();
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) return false;
    try {
      _user = await _authService.getProfile();
      notifyListeners();
      return true;
    } catch (_) {
      await _authService.logout();
      return false;
    }
  }

  String _extractError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      // Dio error with response
      if (msg.contains('error')) {
        try {
          final dioError = e as dynamic;
          return dioError.response?.data?['error'] ?? 'Bir hata oluştu';
        } catch (_) {}
      }
    }
    return 'Bağlantı hatası. Sunucuya ulaşılamıyor.';
  }
}
