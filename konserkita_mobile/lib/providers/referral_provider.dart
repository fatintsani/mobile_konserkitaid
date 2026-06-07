import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ReferralProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _myCode;
  List<dynamic> _conversions = [];
  List<dynamic> _rewards = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get myCode => _myCode;
  List<dynamic> get conversions => _conversions;
  List<dynamic> get rewards => _rewards;

  Future<void> fetchMyCode() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/referrals/my-code');
      if (response.data['success']) {
        _myCode = response.data['data'];
      }
    } catch (e) {
      _error = 'Failed to fetch referral code';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchConversions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/referrals/conversions');
      if (response.data['success']) {
        _conversions = response.data['data']['data'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch conversions';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRewards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/referrals/rewards');
      if (response.data['success']) {
        _rewards = response.data['data']['data'] ?? [];
      }
    } catch (e) {
      _error = 'Failed to fetch rewards';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
