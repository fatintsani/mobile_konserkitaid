import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _subscriptionData;
  List<dynamic> _plans = [];
  List<dynamic> _payments = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get subscriptionData => _subscriptionData;
  List<dynamic> get plans => _plans;
  List<dynamic> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSubscription() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/organizer/subscription');
      if (response.data['success']) {
        _subscriptionData = response.data['data'];
      } else {
        _error = response.data['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/subscription-plans');
      if (response.data['success']) {
        _plans = response.data['data'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> upgradePlan(int planId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/organizer/subscription/upgrade', data: {
        'plan_id': planId
      });
      _isLoading = false;
      notifyListeners();

      if (response.data['success']) {
        return response.data['data'];
      } else {
        _error = response.data['message'];
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> fetchPayments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/organizer/subscription/payments');
      if (response.data['success']) {
        _payments = response.data['data'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
