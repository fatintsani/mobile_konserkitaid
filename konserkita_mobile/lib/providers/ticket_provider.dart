import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';

class TicketProvider with ChangeNotifier {
  final TicketService _ticketService = TicketService();
  Ticket? _selectedTicket;
  bool _isLoading = false;
  String? _error;

  Ticket? get selectedTicket => _selectedTicket;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTicketDetail(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTicket = await _ticketService.getTicketDetail(code);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedTicket = null;
    _error = null;
    notifyListeners();
  }
}
