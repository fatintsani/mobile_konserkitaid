import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _service = NotificationService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _service.getNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    final success = await _service.markAsRead(id);
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = AppNotification(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final success = await _service.markAllAsRead();
    if (success) {
      _notifications = _notifications.map((n) {
        return AppNotification(
          id: n.id,
          userId: n.userId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(int id) async {
    final success = await _service.deleteNotification(id);
    if (success) {
      _notifications.removeWhere((n) => n.id == id);
      notifyListeners();
    }
  }
}
