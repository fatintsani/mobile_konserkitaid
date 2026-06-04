import 'package:flutter/material.dart';

class AppConstants {
  // Base URL for Android Emulator
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // KonserKita Brand Colors
  static const Color primaryColor = Color(0xFF6200EA); // Deep Purple
  static const Color secondaryColor = Color(0xFFFF4D8D); // Pink accent
  static const Color backgroundColor = Color(0xFFF8F7FC); // Light background
  static const Color textColor = Color(0xFF1F2937); // Dark gray

  // Helper for Android emulator image URLs
  static String getImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    if (url.contains('127.0.0.1')) {
      return url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }
}
