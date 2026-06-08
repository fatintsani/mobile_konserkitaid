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

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _socialAuthService.loginWithGoogle();
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithMicrosoft() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _socialAuthService.loginWithMicrosoft();
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
