import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';

class ContentProvider with ChangeNotifier {
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
      final bannerResponse = await http.get(Uri.parse('${AppConstants.baseUrl}/banners'));
      if (bannerResponse.statusCode == 200) {
        final data = json.decode(bannerResponse.body);
        _banners = data['data'];
      }

      final categoryResponse = await http.get(Uri.parse('${AppConstants.baseUrl}/categories'));
      if (categoryResponse.statusCode == 200) {
        final data = json.decode(categoryResponse.body);
        _categories = data['data'];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
