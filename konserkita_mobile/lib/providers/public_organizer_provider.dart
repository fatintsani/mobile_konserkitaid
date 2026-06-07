import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PublicOrganizerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _organizers = [];
  Map<String, dynamic>? _currentOrganizer;
  List<dynamic> _organizerEvents = [];
  List<dynamic> _organizerReviews = [];
  List<dynamic> _followedOrganizers = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get organizers => _organizers;
  Map<String, dynamic>? get currentOrganizer => _currentOrganizer;
  List<dynamic> get organizerEvents => _organizerEvents;
  List<dynamic> get organizerReviews => _organizerReviews;
  List<dynamic> get followedOrganizers => _followedOrganizers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOrganizers({bool popular = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/organizers${popular ? '?popular=1' : ''}');
      if (response.data['success']) {
        _organizers = response.data['data']['data'];
      } else {
        _error = response.data['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrganizerProfile(String slug) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/organizers/$slug');
      if (response.data['success']) {
        _currentOrganizer = response.data['data'];
      } else {
        _error = response.data['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrganizerEvents(String slug) async {
    try {
      final response = await _apiService.dio.get('/organizers/$slug/events');
      if (response.data['success']) {
        _organizerEvents = response.data['data']['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchOrganizerReviews(String slug) async {
    try {
      final response = await _apiService.dio.get('/organizers/$slug/reviews');
      if (response.data['success']) {
        _organizerReviews = response.data['data']['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchFollowedOrganizers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/organizers/following');
      if (response.data['success']) {
        _followedOrganizers = response.data['data']['data'];
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> followOrganizer(int organizerId) async {
    try {
      final response = await _apiService.dio.post('/organizers/$organizerId/follow', data: {});
      if (response.data['success']) {
        if (_currentOrganizer != null && _currentOrganizer!['id'] == organizerId) {
          _currentOrganizer!['is_followed'] = true;
          _currentOrganizer!['total_followers'] = (_currentOrganizer!['total_followers'] ?? 0) + 1;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  Future<bool> unfollowOrganizer(int organizerId) async {
    try {
      final response = await _apiService.dio.delete('/organizers/$organizerId/follow');
      if (response.data['success']) {
        if (_currentOrganizer != null && _currentOrganizer!['id'] == organizerId) {
          _currentOrganizer!['is_followed'] = false;
          _currentOrganizer!['total_followers'] = (_currentOrganizer!['total_followers'] ?? 1) - 1;
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }

  Future<bool> submitReview(int organizerId, int rating, String comment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.post('/organizers/$organizerId/reviews', data: {
        'rating': rating,
        'comment': comment,
      });
      if (response.data['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.data['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
