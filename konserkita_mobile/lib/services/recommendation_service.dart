import 'package:dio/dio.dart';
import '../models/event.dart';
import 'api_service.dart';

class RecommendationService {
  final ApiService _apiService = ApiService();

  Future<List<Event>> getRecommendations() async {
    try {
      final response = await _apiService.dio.get('/recommendations');
      if (response.data['success']) {
        return (response.data['data'] as List)
            .map((e) => Event.fromJson(e))
            .toList();
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to load recommendations');
    }
  }

  Future<bool> recordInteraction(int eventId, String interactionType) async {
    try {
      final response = await _apiService.dio.post('/interactions', data: {
        'event_id': eventId,
        'interaction_type': interactionType,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false; // Silently fail for interaction logging
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await _apiService.dio.get('/preferences');
      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } catch (e) {
      throw Exception('Failed to load preferences');
    }
  }

  Future<bool> updatePreferences({
    List<String>? preferredCategories,
    List<String>? preferredLocations,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (preferredCategories != null) data['preferred_categories'] = preferredCategories;
      if (preferredLocations != null) data['preferred_locations'] = preferredLocations;
      if (minPrice != null) data['min_price'] = minPrice;
      if (maxPrice != null) data['max_price'] = maxPrice;

      final response = await _apiService.dio.put('/preferences', data: data);
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
