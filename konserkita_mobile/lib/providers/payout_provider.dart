import 'package:flutter/material.dart';
import '../models/organizer_payout.dart';
import '../services/payout_service.dart';

class PayoutProvider with ChangeNotifier {
  final PayoutService _payoutService = PayoutService();

  PayoutBalance? _balance;
  List<OrganizerPayout> _payouts = [];
  bool _isLoading = false;
  String? _error;

  PayoutBalance? get balance => _balance;
  List<OrganizerPayout> get payouts => _payouts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchBalance() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _balance = await _payoutService.getBalance();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPayouts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _payouts = await _payoutService.getPayouts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrganizerPayout?> requestPayout(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payout = await _payoutService.requestPayout(data);
      _payouts.insert(0, payout);
      // Re-fetch balance
      await fetchBalance();
      return payout;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<OrganizerPayout?> fetchPayoutDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payout = await _payoutService.getPayoutDetail(id);
      return payout;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
