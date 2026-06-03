import 'package:flutter/material.dart';
import '../services/ticket_service.dart';

class TicketValidationProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _scanResult;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get scanResult => _scanResult;

  Future<bool> validateTicket(String ticketCode) async {
    _isLoading = true;
    _error = null;
    _scanResult = null;
    notifyListeners();

    try {
      final result = await _ticketService.scanTicket(ticketCode);
      _scanResult = result;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResult() {
    _scanResult = null;
    _error = null;
    notifyListeners();
  }
}
