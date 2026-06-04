import 'package:flutter/material.dart';
import '../services/checkout_service.dart';
import '../models/ticket_type.dart';

class CheckoutProvider with ChangeNotifier {
  final CheckoutService _checkoutService = CheckoutService();
  
  final Map<TicketType, int> _selectedTickets = {};
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _transactionResult;
  String? _promoCode;
  double _discountAmount = 0;

  Map<TicketType, int> get selectedTickets => _selectedTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get transactionResult => _transactionResult;
  String? get promoCode => _promoCode;
  double get discountAmount => _discountAmount;

  void addTicket(TicketType ticketType) {
    int currentQuantity = _selectedTickets[ticketType] ?? 0;
    if (currentQuantity < ticketType.maxBuy && currentQuantity < ticketType.stock) {
      _selectedTickets[ticketType] = currentQuantity + 1;
      notifyListeners();
    }
  }

  void removeTicket(TicketType ticketType) {
    int currentQuantity = _selectedTickets[ticketType] ?? 0;
    if (currentQuantity > 0) {
      _selectedTickets[ticketType] = currentQuantity - 1;
      if (_selectedTickets[ticketType] == 0) {
        _selectedTickets.remove(ticketType);
      }
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedTickets.clear();
    _transactionResult = null;
    _error = null;
    _promoCode = null;
    _discountAmount = 0;
    notifyListeners();
  }

  double get subtotal {
    double total = 0;
    _selectedTickets.forEach((ticket, quantity) {
      total += ticket.price * quantity;
    });
    return total;
  }

  int get totalQuantity {
    int total = 0;
    _selectedTickets.forEach((_, quantity) {
      total += quantity;
    });
    return total;
  }

  double get finalTotal {
    return subtotal - _discountAmount;
  }

  Future<bool> applyPromo(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _checkoutService.validatePromo(code, subtotal);
      _promoCode = result['code'];
      _discountAmount = double.parse(result['discount_amount'].toString());
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _promoCode = null;
      _discountAmount = 0;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void removePromo() {
    _promoCode = null;
    _discountAmount = 0;
    _error = null;
    notifyListeners();
  }

  Future<bool> checkout(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      List<Map<String, dynamic>> items = [];
      _selectedTickets.forEach((ticket, quantity) {
        items.add({
          'ticket_type_id': ticket.id,
          'quantity': quantity,
        });
      });

      _transactionResult = await _checkoutService.createCheckout(eventId, items, promoCode: _promoCode);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String> checkPaymentStatus(int transactionId) async {
    _isLoading = true;
    notifyListeners();

    String status = await _checkoutService.checkPaymentStatus(transactionId);
    
    _isLoading = false;
    notifyListeners();
    return status;
  }
}
