import 'dart:convert';
import '../models/organizer_payout.dart';
import 'api_service.dart';

class PayoutService {
  final ApiService _apiService = ApiService();

  Future<PayoutBalance> getBalance() async {
    final response = await _apiService.get('/organizer/payouts/balance');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PayoutBalance.fromJson(data['data']);
    } else {
      throw Exception('Failed to load payout balance');
    }
  }

  Future<List<OrganizerPayout>> getPayouts() async {
    final response = await _apiService.get('/organizer/payouts');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> list = data['data'];
      return list.map((json) => OrganizerPayout.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load payouts');
    }
  }

  Future<OrganizerPayout> getPayoutDetail(int id) async {
    final response = await _apiService.get('/organizer/payouts/$id');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OrganizerPayout.fromJson(data['data']);
    } else {
      throw Exception('Failed to load payout details');
    }
  }

  Future<OrganizerPayout> requestPayout(Map<String, dynamic> data) async {
    final response = await _apiService.post('/organizer/payouts', data);
    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return OrganizerPayout.fromJson(responseData['data']);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to request payout');
    }
  }
}
