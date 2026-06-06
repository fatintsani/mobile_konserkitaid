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
  List<dynamic> _categories = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<Event> get events => _events;
  Map<String, dynamic>? get eventDetail => _eventDetail;
  Map<String, dynamic>? get eventSales => _eventSales;
  List<dynamic> get attendees => _attendees;
  List<dynamic> get categories => _categories;

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

  Future<void> fetchCategories() async {
    try {
      _categories = await _service.getCategories();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createEvent(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createEvent(data);
      await fetchEvents();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateEvent(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateEvent(id, data);
      await fetchEvents();
      await fetchEventDetail(id);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteEvent(id);
      await fetchEvents();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTicketType(int eventId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.createTicketType(eventId, data);
      await fetchEventDetail(eventId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateTicketType(int eventId, int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.updateTicketType(id, data);
      await fetchEventDetail(eventId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTicketType(int eventId, int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteTicketType(id);
      await fetchEventDetail(eventId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
