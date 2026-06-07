import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/recommendation_service.dart';

class RecommendationProvider with ChangeNotifier {
  final RecommendationService _service = RecommendationService();

  List<Event> _recommendations = [];
  Map<String, dynamic>? _preferences;
  bool _isLoading = false;
  String? _error;

  List<Event> get recommendations => _recommendations;
  Map<String, dynamic>? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecommendations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _recommendations = await _service.getRecommendations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _preferences = await _service.getPreferences();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreferences({
    List<String>? preferredCategories,
    List<String>? preferredLocations,
    double? minPrice,
    double? maxPrice,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await _service.updatePreferences(
      preferredCategories: preferredCategories,
      preferredLocations: preferredLocations,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );

    if (success) {
      await fetchPreferences();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    
    return success;
  }

  Future<void> logInteraction(int eventId, String type) async {
    await _service.recordInteraction(eventId, type);
  }
}
