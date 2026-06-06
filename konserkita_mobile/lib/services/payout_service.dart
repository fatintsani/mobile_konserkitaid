import 'package:dio/dio.dart';
import '../models/organizer_payout.dart';
import 'api_service.dart';

class PayoutService {
  final ApiService _apiService = ApiService();

  Future<PayoutBalance> getBalance() async {
    try {
      final response = await _apiService.dio.get('/organizer/payouts/balance');
      if (response.data['success']) {
        return PayoutBalance.fromJson(response.data['data']);
      }
      throw Exception('Failed to load payout balance');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load payout balance');
    }
  }

  Future<List<OrganizerPayout>> getPayouts() async {
    try {
      final response = await _apiService.dio.get('/organizer/payouts');
      if (response.data['success']) {
        final List<dynamic> list = response.data['data'];
        return list.map((json) => OrganizerPayout.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load payouts');
    }
  }

  Future<OrganizerPayout> getPayoutDetail(int id) async {
    try {
      final response = await _apiService.dio.get('/organizer/payouts/$id');
      if (response.data['success']) {
        return OrganizerPayout.fromJson(response.data['data']);
      }
      throw Exception('Failed to load payout details');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load payout details');
    }
  }

  Future<OrganizerPayout> requestPayout(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.post('/organizer/payouts', data: data);
      if (response.data['success']) {
        return OrganizerPayout.fromJson(response.data['data']);
      }
      throw Exception('Failed to request payout');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to request payout');
    }
  }
}
