import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<User?> login(String email, String password) async {
    try {
      final response = await _apiService.dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data['success']) {
        final token = response.data['data']['token'];
        final user = User.fromJson(response.data['data']['user']);
        
        await _storage.write(key: 'auth_token', value: token);
        return user;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }

  Future<User?> register(String name, String email, String password, String passwordConfirmation) async {
    try {
      final response = await _apiService.dio.post('/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      if (response.data['success']) {
        final token = response.data['data']['token'];
        final user = User.fromJson(response.data['data']['user']);
        
        await _storage.write(key: 'auth_token', value: token);
        return user;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Registration failed');
    }
  }

  Future<User?> getProfile() async {
    try {
      final response = await _apiService.dio.get('/profile');
      if (response.data['success']) {
        return User.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.dio.put('/profile', data: data);
      if (response.data['success']) {
        return User.fromJson(response.data['data']);
      }
      throw Exception(response.data['message']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/logout');
    } catch (e) {
      // Ignore error if logout fails on server
    } finally {
      await _storage.delete(key: 'auth_token');
    }
  }

  Future<Map<String, dynamic>> getPasskeyRegisterOptions() async {
    try {
      final response = await _apiService.dio.post('/passkeys/register/options');
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get passkey options');
    }
  }

  Future<void> verifyPasskeyRegistration(Map<String, dynamic> responseData) async {
    try {
      await _apiService.dio.post('/passkeys/register/verify', data: responseData);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to verify passkey');
    }
  }

  Future<Map<String, dynamic>> getPasskeyLoginOptions(String email) async {
    try {
      final response = await _apiService.dio.post('/passkeys/login/options', data: {'email': email});
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get login options');
    }
  }

  Future<User?> verifyPasskeyLogin(Map<String, dynamic> responseData, String email) async {
    try {
      final response = await _apiService.dio.post('/passkeys/login/verify', data: {
        ...responseData,
        'email': email,
      });

      if (response.data['message'] == 'Login successful') {
        final token = response.data['token'];
        final user = User.fromJson(response.data['user']);
        
        await _storage.write(key: 'auth_token', value: token);
        return user;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Login failed');
    }
  }
}
