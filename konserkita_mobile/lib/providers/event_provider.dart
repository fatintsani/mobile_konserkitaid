import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService = EventService();
  List<Event> _events = [];
  Event? _selectedEvent;
  bool _isLoading = false;
  String? _error;

  String? _searchQuery;
  String? _selectedCity;
  int? _selectedCategoryId;
  String? _startDate;
  String? _endDate;
  double? _minPrice;
  double? _maxPrice;

  List<Event> get events => _events;
  Event? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get searchQuery => _searchQuery;
  String? get selectedCity => _selectedCity;
  int? get selectedCategoryId => _selectedCategoryId;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;

  Future<void> fetchEvents({bool resetFilters = false}) async {
    if (resetFilters) {
      _searchQuery = null;
      _selectedCity = null;
      _selectedCategoryId = null;
      _startDate = null;
      _endDate = null;
      _minPrice = null;
      _maxPrice = null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _eventService.getEvents(
        search: _searchQuery,
        city: _selectedCity,
        categoryId: _selectedCategoryId,
        startDate: _startDate,
        endDate: _endDate,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    fetchEvents();
  }

  void setFilters({
    String? city,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minPrice,
    double? maxPrice,
  }) {
    _selectedCity = city;
    _selectedCategoryId = categoryId;
    _startDate = startDate;
    _endDate = endDate;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    fetchEvents();
  }

  Future<void> fetchEventDetail(int id) async {
    _setLoading(true);
    try {
      _selectedEvent = await _eventService.getEventDetail(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
