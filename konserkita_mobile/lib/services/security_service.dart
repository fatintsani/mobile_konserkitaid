import 'package:dio/dio.dart';
import 'api_service.dart';

class SecurityService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getActiveSessions() async {
    final response = await _apiService.dio.get('/security/sessions');
    return response.data;
  }

  Future<void> revokeSession(int id) async {
    await _apiService.dio.delete('/security/sessions/$id');
  }

  Future<void> revokeOtherSessions() async {
    await _apiService.dio.delete('/security/sessions/revoke-others');
  }

  Future<Map<String, dynamic>> getLoginActivities({int page = 1}) async {
    final response = await _apiService.dio.get(
      '/security/login-activities',
      queryParameters: {'page': page},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getSecurityAlerts({int page = 1}) async {
    final response = await _apiService.dio.get(
      '/security/alerts',
      queryParameters: {'page': page},
    );
    return response.data;
  }

  Future<void> markAlertAsRead(int id) async {
    await _apiService.dio.put('/security/alerts/$id/read');
  }

  Future<void> markAllAlertsAsRead() async {
    await _apiService.dio.put('/security/alerts/read-all');
  }
}
