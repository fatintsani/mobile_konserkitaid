import 'package:dio/dio.dart';
import '../models/ticket.dart';
import 'api_service.dart';

class TicketService {
  final ApiService _apiService = ApiService();

  Future<List<Ticket>> getMyTickets() async {
    try {
      final response = await _apiService.dio.get('/tickets');
      if (response.data['success']) {
        final data = response.data['data'] as List;
        return data.map((e) => Ticket.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load tickets');
    }
  }

  Future<Ticket> getTicketDetail(String code) async {
    try {
      final response = await _apiService.dio.get('/tickets/$code');
      if (response.data['success']) {
        return Ticket.fromJson(response.data['data']);
      }
      throw Exception('Ticket not found');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load ticket details');
    }
  }

  Future<Map<String, dynamic>> scanTicket(String ticketCode) async {
    try {
      final response = await _apiService.dio.post('/tickets/scan', data: {
        'ticket_code': ticketCode,
      });
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to scan ticket');
    }
  }
}
