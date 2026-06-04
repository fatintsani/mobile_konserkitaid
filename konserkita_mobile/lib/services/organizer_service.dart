import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/event.dart';

class OrganizerService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await _apiService.dio.get('/organizer/dashboard');
      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load dashboard data');
    }
  }

  Future<List<Event>> getEvents() async {
    try {
      final response = await _apiService.dio.get('/organizer/events');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Event.fromJson(json)).toList();
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load events');
    }
  }

  Future<Map<String, dynamic>> getEventDetail(int id) async {
    try {
      final response = await _apiService.dio.get('/organizer/events/$id');
      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load event detail');
    }
  }

  Future<Map<String, dynamic>> getEventSales(int id) async {
    try {
      final response = await _apiService.dio.get('/organizer/events/$id/sales');
      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load event sales');
    }
  }

  Future<List<dynamic>> getEventAttendees(int id) async {
    try {
      final response = await _apiService.dio.get('/organizer/events/$id/attendees');
      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load attendees');
    }
  }
}
