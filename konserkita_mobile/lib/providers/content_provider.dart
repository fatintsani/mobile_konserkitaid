import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class ContentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<dynamic> _banners = [];
  List<dynamic> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get banners => _banners;
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchContent() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final bannerResponse = await _apiService.dio.get('/banners');
      if (bannerResponse.data['success'] == true) {
        _banners = bannerResponse.data['data'];
      }

      final categoryResponse = await _apiService.dio.get('/categories');
      if (categoryResponse.data['success'] == true) {
        _categories = categoryResponse.data['data'];
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
}
