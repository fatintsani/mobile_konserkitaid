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

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/organizer/events', data: data);
      if (response.data['success']) return response.data['data'];
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create event');
    }
  }

  Future<Map<String, dynamic>> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/organizer/events/$id', data: data);
      if (response.data['success']) return response.data['data'];
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update event');
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      final response = await _apiService.dio.delete('/organizer/events/$id');
      if (!response.data['success']) throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete event');
    }
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiService.dio.get('/event-categories');
      if (response.data['success']) return response.data['data'];
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load categories');
    }
  }

  Future<Map<String, dynamic>> createTicketType(int eventId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/organizer/events/$eventId/ticket-types', data: data);
      if (response.data['success']) return response.data['data'];
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create ticket type');
    }
  }

  Future<Map<String, dynamic>> updateTicketType(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/organizer/ticket-types/$id', data: data);
      if (response.data['success']) return response.data['data'];
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update ticket type');
    }
  }

  Future<void> deleteTicketType(int id) async {
    try {
      final response = await _apiService.dio.delete('/organizer/ticket-types/$id');
      if (!response.data['success']) throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete ticket type');
    }
  }
}
