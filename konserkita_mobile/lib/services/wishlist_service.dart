import 'package:dio/dio.dart';
import '../models/event.dart';
import 'api_service.dart';

class WishlistService {
  final ApiService _apiService = ApiService();

  Future<List<Event>> getWishlists() async {
    try {
      final response = await _apiService.dio.get('/wishlists');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) {
          // The API returns Wishlist items which have an 'event' object
          return Event.fromJson(json['event']);
        }).toList();
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load wishlists');
    }
  }

  Future<bool> addToWishlist(int eventId) async {
    try {
      final response = await _apiService.dio.post('/wishlists', data: {
        'event_id': eventId,
      });
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromWishlist(int eventId) async {
    try {
      final response = await _apiService.dio.delete('/wishlists/$eventId');
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }
}
