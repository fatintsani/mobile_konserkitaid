import 'package:dio/dio.dart';
import 'api_service.dart';

class CheckoutService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createCheckout(int eventId, List<Map<String, dynamic>> items, {String? promoCode, List<int>? seatIds}) async {
    try {
      final response = await _apiService.dio.post('/checkout', data: {
        'event_id': eventId,
        'tickets': items,
        'promo_code': promoCode,
        if (seatIds != null && seatIds.isNotEmpty) 'seat_ids': seatIds,
      });
      
      if (response.data['success']) {
        return response.data['data']; // Returns transaction data
      }
      throw Exception('Checkout failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to process checkout');
    }
  }

  Future<Map<String, dynamic>> validatePromo(String code, double subtotal) async {
    try {
      final response = await _apiService.dio.post('/promos/validate', data: {
        'promo_code': code,
        'subtotal': subtotal,
      });
      if (response.data['success']) {
        return response.data['data'];
      }
      throw Exception('Gagal memvalidasi promo');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Promo tidak valid atau kuota habis');
    }
  }

  Future<String> checkPaymentStatus(int transactionId) async {
    try {
      final response = await _apiService.dio.get('/payments/status/$transactionId');
      if (response.data['success']) {
        return response.data['data']['payment_status'];
      }
      return 'failed';
    } catch (e) {
      return 'failed';
    }
  }
}
