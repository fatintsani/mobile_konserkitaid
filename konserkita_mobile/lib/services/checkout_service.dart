import 'package:dio/dio.dart';
import 'api_service.dart';

class CheckoutService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createCheckout(int eventId, List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiService.dio.post('/checkout', data: {
        'tickets': items,
      });
      
      if (response.data['success']) {
        return response.data['data']; // Returns transaction data
      }
      throw Exception('Checkout failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to process checkout');
    }
  }

  // Simulasi callback webhook Midtrans (Karena belum setup Midtrans API seutuhnya)
  Future<bool> simulatePaymentSuccess(int transactionId) async {
    try {
      await _apiService.dio.post('/payment/notification', data: {
        'order_id': transactionId,
        'transaction_status': 'settlement', // Simulate success
        'gross_amount': 0, // Mock amount
        'payment_type': 'bank_transfer',
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
