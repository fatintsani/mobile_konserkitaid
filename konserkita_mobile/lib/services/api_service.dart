import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';
import '../routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  late Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final prefs = await SharedPreferences.getInstance();
        final lang = prefs.getString('languageCode') ?? 'id';
        options.headers['Accept-Language'] = lang;
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: 'auth_token');
          await _storage.delete(key: 'user_data');
          AppRouter.router.go('/login');
        } else if (e.response?.statusCode == 429) {
          e.response?.data = {
            'message': 'Terlalu banyak percobaan. Coba lagi beberapa saat.',
            ...(e.response?.data is Map ? e.response?.data as Map : {}),
          };
        }
        return handler.next(e);
      }
    ));
  }
}
