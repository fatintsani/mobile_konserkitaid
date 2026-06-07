import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PublicOrganizerProvider with ChangeNotifier {
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
      final response = await ApiService.get('/organizers${popular ? '?popular=1' : ''}');
      if (response['success']) {
        _organizers = response['data']['data'];
      } else {
        _error = response['message'];
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
      final response = await ApiService.get('/organizers/$slug');
      if (response['success']) {
        _currentOrganizer = response['data'];
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchOrganizerEvents(String slug) async {
    try {
      final response = await ApiService.get('/organizers/$slug/events');
      if (response['success']) {
        _organizerEvents = response['data']['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> fetchOrganizerReviews(String slug) async {
    try {
      final response = await ApiService.get('/organizers/$slug/reviews');
      if (response['success']) {
        _organizerReviews = response['data']['data'];
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
      final response = await ApiService.get('/organizers/following');
      if (response['success']) {
        _followedOrganizers = response['data']['data'];
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> followOrganizer(int organizerId) async {
    try {
      final response = await ApiService.post('/organizers/$organizerId/follow', {});
      if (response['success']) {
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
      final response = await ApiService.delete('/organizers/$organizerId/follow');
      if (response['success']) {
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
      final response = await ApiService.post('/organizers/$organizerId/reviews', {
        'rating': rating,
        'comment': comment,
      });
      if (response['success']) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
