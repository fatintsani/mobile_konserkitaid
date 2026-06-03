import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  bool _isCheckingAuth = true;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isCheckingAuth => _isCheckingAuth;
  String? get error => _error;

  Future<void> checkAuthStatus() async {
    _isCheckingAuth = true;
    notifyListeners();
    
    try {
      _user = await _authService.getProfile();
    } catch (e) {
      _user = null;
    } finally {
      _isCheckingAuth = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(String name, String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.updateProfile({
        'name': name,
        'phone': phone,
      });
      _user = user;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authService.login(email, password);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    _setLoading(true);
    try {
      _user = await _authService.register(name, email, password, passwordConfirmation);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _user = null;
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
