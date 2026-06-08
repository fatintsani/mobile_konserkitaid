import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import '../models/user.dart';
import 'api_service.dart';

class SocialAuthService {
  final ApiService _apiService = ApiService();
  final _storage = const FlutterSecureStorage();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FlutterAppAuth _appAuth = const FlutterAppAuth();

  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;

      if (accessToken == null) {
        throw Exception('Failed to get access token from Google');
      }

      return await _sendTokenToBackend(accessToken, 'google');
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<User?> loginWithMicrosoft() async {
    try {
      // Configuration for Microsoft OAuth
      const String clientId = 'YOUR_MICROSOFT_CLIENT_ID';
      const String redirectUrl = 'konserkita://oauth2redirect';
      const String discoveryUrl = 'https://login.microsoftonline.com/common/v2.0/.well-known/openid-configuration';

      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
        ),
      );

      if (result?.accessToken != null) {
        return await _sendTokenToBackend(result!.accessToken!, 'microsoft');
      }
      
      return null;
    } catch (e) {
      throw Exception('Microsoft Sign-In failed: $e');
    }
  }

  Future<User?> _sendTokenToBackend(String accessToken, String provider) async {
    try {
      final response = await _apiService.dio.post('/auth/$provider', data: {
        'access_token': accessToken,
      });

      if (response.data['success']) {
        final token = response.data['data']['token'];
        final user = User.fromJson(response.data['data']['user']);
        
        await _storage.write(key: 'auth_token', value: token);
        return user;
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Social login failed on backend');
    }
  }
}
