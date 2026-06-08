import 'package:flutter/foundation.dart';
import '../services/social_auth_service.dart';
import '../models/user.dart';

class SocialAuthProvider with ChangeNotifier {
  final SocialAuthService _socialAuthService = SocialAuthService();
  
  bool _isLoading = false;
  String? _error;
  User? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;

  Future<Map<String, dynamic>> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _socialAuthService.loginWithGoogle();
      if (result['requires_2fa'] == true) {
        _isLoading = false;
        notifyListeners();
        return result;
      }
      
      if (result['success'] == true) {
        _user = result['user'];
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Google Sign-In failed or canceled'};
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loginWithMicrosoft() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _socialAuthService.loginWithMicrosoft();
      if (result['requires_2fa'] == true) {
        _isLoading = false;
        notifyListeners();
        return result;
      }
      
      if (result['success'] == true) {
        _user = result['user'];
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      }
      
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Microsoft Sign-In failed or canceled'};
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }
}
