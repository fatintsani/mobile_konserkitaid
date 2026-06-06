import 'package:dio/dio.dart';
import '../models/transaction.dart';
import 'api_service.dart';

class TransactionService {
  final ApiService _apiService = ApiService();

  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _apiService.dio.get('/transactions');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => Transaction.fromJson(json)).toList();
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load transactions');
    }
  }

  Future<Transaction> getTransactionDetail(int id) async {
    try {
      final response = await _apiService.dio.get('/transactions/$id');
      if (response.data['success']) {
        return Transaction.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load transaction details');
    }
  }
}
