import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../models/review.dart';
import '../services/api_service.dart';

class ReviewProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Review> _eventReviews = [];
  List<Review> _myReviews = [];
  Map<String, dynamic>? _ratingSummary;
  bool _isLoading = false;
  String? _error;

  List<Review> get eventReviews => _eventReviews;
  List<Review> get myReviews => _myReviews;
  Map<String, dynamic>? get ratingSummary => _ratingSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchEventReviews(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/events/$eventId/reviews');
      if (response.data['success'] == true) {
        final List data = response.data['data']['data'];
        _eventReviews = data.map((json) => Review.fromJson(json)).toList();
      }
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data['message'] ?? e.message;
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRatingSummary(int eventId) async {
    try {
      final response = await _apiService.dio.get('/events/$eventId/rating-summary');
      if (response.data['success'] == true) {
        _ratingSummary = response.data['data'];
        notifyListeners();
      }
    } catch (e) {
      // It's okay if summary fails silently
    }
  }

  Future<void> fetchMyReviews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/my-reviews'); // requiresAuth handled by dio interceptor
      if (response.data['success'] == true) {
        final List data = response.data['data']['data'];
        _myReviews = data.map((json) => Review.fromJson(json)).toList();
      }
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data['message'] ?? e.message;
      } else {
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReview(int eventId, int rating, String? comment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.post(
        '/events/$eventId/reviews',
        data: {
          'rating': rating,
          'comment': comment,
        },
      );

      if (response.data['success'] == true) {
        await fetchMyReviews();
        return true;
      }
      return false;
    } catch (e) {
      if (e is DioException) {
        _error = e.response?.data['message'] ?? e.message;
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
