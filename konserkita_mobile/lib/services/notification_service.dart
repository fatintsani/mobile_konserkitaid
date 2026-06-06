import 'package:dio/dio.dart';
import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _apiService.dio.get('/notifications');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => AppNotification.fromJson(json)).toList();
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load notifications');
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final response = await _apiService.dio.put('/notifications/$id/read');
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiService.dio.put('/notifications/read-all');
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final response = await _apiService.dio.delete('/notifications/$id');
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }
}
