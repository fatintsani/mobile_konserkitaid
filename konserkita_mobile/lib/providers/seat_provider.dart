import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class SeatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _seatMapData;
  List<int> _selectedSeatIds = [];
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get seatMapData => _seatMapData;
  List<int> get selectedSeatIds => _selectedSeatIds;

  Future<void> fetchSeatMap(int eventId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.dio.get('/events/$eventId/seat-map');
      if (response.data['success']) {
        _seatMapData = response.data['data'];
        _selectedSeatIds = []; // clear selection on fetch
      } else {
        _error = response.data['message'] ?? 'Failed to load seat map';
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? e.toString();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSeatSelection(int seatId, String status) {
    if (status != 'available' && status != 'selected') return;
    
    if (_selectedSeatIds.contains(seatId)) {
      _selectedSeatIds.remove(seatId);
    } else {
      _selectedSeatIds.add(seatId);
    }
    notifyListeners();
  }

  Future<bool> holdSeats(int eventId) async {
    if (_selectedSeatIds.isEmpty) return false;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.dio.post('/events/$eventId/seats/hold', data: {
        'seat_ids': _selectedSeatIds,
      });
      
      _isLoading = false;
      notifyListeners();
      return response.data['success'];
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> releaseSeats(int eventId) async {
    if (_selectedSeatIds.isEmpty) return;
    
    try {
      await _apiService.dio.post('/events/$eventId/seats/release', data: {
        'seat_ids': _selectedSeatIds,
      });
      _selectedSeatIds = [];
      notifyListeners();
    } catch (e) {
      // Background failure
    }
  }
}
