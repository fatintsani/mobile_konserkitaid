import 'package:dio/dio.dart';
import '../models/event.dart';
import 'api_service.dart';

class EventService {
  final ApiService _apiService = ApiService();

  Future<List<Event>> getEvents() async {
    try {
      final response = await _apiService.dio.get('/events');
      if (response.data['success']) {
        final data = response.data['data']['data'] as List; // Pagination data array
        return data.map((e) => Event.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load events');
    }
  }

  Future<Event> getEventDetail(int id) async {
    try {
      final response = await _apiService.dio.get('/events/$id');
      if (response.data['success']) {
        return Event.fromJson(response.data['data']);
      }
      throw Exception('Event not found');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load event detail');
    }
  }
}
