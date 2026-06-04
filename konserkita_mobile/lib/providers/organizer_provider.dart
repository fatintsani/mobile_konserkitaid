import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/organizer_service.dart';

class OrganizerProvider with ChangeNotifier {
  final OrganizerService _service = OrganizerService();

  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _dashboardData;
  List<Event> _events = [];
  Map<String, dynamic>? _eventDetail;
  Map<String, dynamic>? _eventSales;
  List<dynamic> _attendees = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<Event> get events => _events;
  Map<String, dynamic>? get eventDetail => _eventDetail;
  Map<String, dynamic>? get eventSales => _eventSales;
  List<dynamic> get attendees => _attendees;

  Future<void> fetchDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboardData = await _service.getDashboard();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _service.getEvents();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventDetail(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _eventDetail = await _service.getEventDetail(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventSales(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _eventSales = await _service.getEventSales(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEventAttendees(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _attendees = await _service.getEventAttendees(id);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
