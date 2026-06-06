import 'package:dio/dio.dart';
import '../models/event.dart';
import 'api_service.dart';

class EventService {
  final ApiService _apiService = ApiService();

  Future<List<Event>> getEvents({
    String? search,
    String? city,
    int? categoryId,
    String? startDate,
    String? endDate,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (startDate != null && startDate.isNotEmpty) queryParams['start_date'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['end_date'] = endDate;
      if (minPrice != null) queryParams['min_price'] = minPrice;
      if (maxPrice != null) queryParams['max_price'] = maxPrice;

      final response = await _apiService.dio.get('/events', queryParameters: queryParams);
      if (response.data['success']) {
        final data = response.data['data']['data'] as List; // Pagination data array
        return data.map((e) => Event.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load events');
    }
  }

  Future<Event> getEventDetail(int id) async {
    try {
      final response = await _apiService.dio.get('/events/$id');
      if (response.data['success']) {
        return Event.fromJson(response.data['data']);
      }
      throw Exception('Event not found');
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load event detail');
    }
  }
}
