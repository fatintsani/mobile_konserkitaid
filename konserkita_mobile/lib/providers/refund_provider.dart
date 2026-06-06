import 'package:flutter/foundation.dart';
import '../models/refund.dart';
import '../services/refund_service.dart';

class RefundProvider with ChangeNotifier {
  final RefundService _refundService = RefundService();
  
  List<Refund> _refunds = [];
  bool _isLoading = false;
  String? _error;

  List<Refund> get refunds => _refunds;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchMyRefunds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _refunds = await _refundService.getMyRefunds();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Refund?> submitRefundRequest(int transactionId, String reason) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final refund = await _refundService.submitRefundRequest(transactionId, reason);
      _refunds.insert(0, refund);
      return refund;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
