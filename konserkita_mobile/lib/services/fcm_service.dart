import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/api_service.dart';

// Top level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> init() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions (iOS and Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Initialize local notifications for foreground display
      const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
      await _localNotifications.initialize(initSettings, onDidReceiveNotificationResponse: _onNotificationTap);

      // Create channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
              ),
            ),
            payload: message.data['type'],
          );
        }
      });

      // Handle click when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationAction(message.data);
      });

      // Handle click when app is terminated
      RemoteMessage? initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationAction(initialMessage.data);
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      _handleNotificationAction({'type': response.payload});
    }
  }

  void _handleNotificationAction(Map<String, dynamic> data) {
    // Navigation logic based on notification type
    // Example: if data['type'] == 'review', navigate to reviews page
    // This typically uses a global navigator key or GoRouter instance
    print("Notification clicked with data: $data");
  }

  Future<void> registerToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _sendTokenToBackend(token);
      }

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      print("Failed to get FCM token: $e");
    }
  }

  Future<void> unregisterToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _apiService.dio.delete('/device-tokens', data: {'token': token});
      }
      await _fcm.deleteToken();
    } catch (e) {
      print("Failed to unregister FCM token: $e");
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      String platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');
      await _apiService.dio.post('/device-tokens', data: {
        'token': token,
        'platform': platform,
        'device_name': Platform.localHostname,
      });
      print("Token registered to backend successfully");
    } catch (e) {
      print("Failed to send token to backend: $e");
    }
  }
}
