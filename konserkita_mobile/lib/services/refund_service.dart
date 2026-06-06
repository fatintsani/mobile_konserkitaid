import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/refund.dart';
import 'api_service.dart';

class RefundService {
  final ApiService _apiService = ApiService();

  Future<List<Refund>> getMyRefunds() async {
    try {
      final response = await _apiService.dio.get('/refunds');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Refund.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch refunds');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch refunds');
      }
      throw Exception(e.toString());
    }
  }

  Future<Refund> getRefundDetail(int id) async {
    try {
      final response = await _apiService.dio.get('/refunds/$id');
      if (response.statusCode == 200) {
        return Refund.fromJson(response.data['data']);
      }
      throw Exception('Failed to fetch refund detail');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to fetch refund detail');
      }
      throw Exception(e.toString());
    }
  }

  Future<Refund> submitRefundRequest(int transactionId, String reason) async {
    try {
      final response = await _apiService.dio.post('/refunds', data: {
        'transaction_id': transactionId,
        'reason': reason,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Refund.fromJson(response.data['data']);
      }
      throw Exception('Failed to submit refund');
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['message'] ?? 'Failed to submit refund');
      }
      throw Exception(e.toString());
    }
  }
}
