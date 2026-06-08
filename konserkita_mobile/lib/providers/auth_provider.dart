import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

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
      if (_user != null) {
        FCMService().registerToken();
      }
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

  Future<Map<String, dynamic>> login(String email, String password) async {
    _setLoading(true);
    try {
      final result = await _authService.login(email, password);
      if (result['requires_2fa'] == true) {
        return result;
      }
      if (result['success'] == true) {
        _user = result['user'];
        FCMService().registerToken();
        return {'success': true};
      }
      return {'success': false, 'message': 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> getPasskeyLoginOptions(String email) async {
    return await _authService.getPasskeyLoginOptions(email);
  }

  Future<Map<String, dynamic>> getPasskeyRegisterOptions() async {
    return await _authService.getPasskeyRegisterOptions();
  }

  Future<void> verifyPasskeyRegistration(Map<String, dynamic> responseData) async {
    await _authService.verifyPasskeyRegistration(responseData);
  }

  Future<Map<String, dynamic>> verifyPasskeyLogin(Map<String, dynamic> response, String email) async {
    _setLoading(true);
    try {
      final result = await _authService.verifyPasskeyLogin(response, email);
      if (result['requires_2fa'] == true) {
        return result;
      }
      if (result['success'] == true) {
        _user = result['user'];
        FCMService().registerToken();
        return {'success': true};
      }
      return {'success': false, 'message': 'Passkey login failed'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String name, String email, String password, String passwordConfirmation) async {
    _setLoading(true);
    try {
      _user = await _authService.register(name, email, password, passwordConfirmation);
      if (_user != null) {
        FCMService().registerToken();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await FCMService().unregisterToken();
    await _authService.logout();
    _user = null;
    _setLoading(false);
  }

  // 2FA methods
  Future<Map<String, dynamic>> setup2FA() async {
    return await _authService.setup2FA();
  }

  Future<List<String>> confirm2FA(String code) async {
    return await _authService.confirm2FA(code);
  }

  Future<void> disable2FA() async {
    await _authService.disable2FA();
  }

  Future<List<String>> regenerateRecoveryCodes() async {
    return await _authService.regenerateRecoveryCodes();
  }

  Future<bool> challenge2FA(String temporaryToken, String code, {bool isRecoveryCode = false}) async {
    _setLoading(true);
    try {
      _user = await _authService.challenge2FA(temporaryToken, code, isRecoveryCode: isRecoveryCode);
      if (_user != null) {
        FCMService().registerToken();
        return true;
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
