import 'package:flutter/material.dart';
import '../services/checkout_service.dart';
import '../models/ticket_type.dart';

class CheckoutProvider with ChangeNotifier {
  final CheckoutService _checkoutService = CheckoutService();
  
  Map<TicketType, int> _selectedTickets = {};
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _transactionResult;

  Map<TicketType, int> get selectedTickets => _selectedTickets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get transactionResult => _transactionResult;

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

      _transactionResult = await _checkoutService.createCheckout(eventId, items);
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

  Future<bool> simulatePaymentSuccess() async {
    if (_transactionResult != null) {
      _isLoading = true;
      notifyListeners();

      bool success = await _checkoutService.simulatePaymentSuccess(_transactionResult!['id']);
      
      _isLoading = false;
      notifyListeners();
      return success;
    }
    return false;
  }
}
