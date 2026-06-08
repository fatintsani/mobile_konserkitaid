import 'package:flutter/foundation.dart';
import '../services/security_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  
  List<dynamic> _sessions = [];
  bool _isLoadingSessions = false;
  String? _sessionsError;

  List<dynamic> _activities = [];
  bool _isLoadingActivities = false;
  String? _activitiesError;
  int _currentActivityPage = 1;
  bool _hasMoreActivities = true;

  List<dynamic> get sessions => _sessions;
  bool get isLoadingSessions => _isLoadingSessions;
  String? get sessionsError => _sessionsError;

  List<dynamic> get activities => _activities;
  bool get isLoadingActivities => _isLoadingActivities;
  String? get activitiesError => _activitiesError;
  bool get hasMoreActivities => _hasMoreActivities;

  Future<void> fetchSessions() async {
    _isLoadingSessions = true;
    _sessionsError = null;
    notifyListeners();

    try {
      _sessions = await _securityService.getActiveSessions();
    } catch (e) {
      _sessionsError = e.toString();
    } finally {
      _isLoadingSessions = false;
      notifyListeners();
    }
  }

  Future<void> revokeSession(int id) async {
    try {
      await _securityService.revokeSession(id);
      _sessions.removeWhere((session) => session['id'] == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> revokeOtherSessions() async {
    try {
      await _securityService.revokeOtherSessions();
      _sessions.removeWhere((session) => session['is_current_device'] != true);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchLoginActivities({bool refresh = false}) async {
    if (refresh) {
      _currentActivityPage = 1;
      _activities = [];
      _hasMoreActivities = true;
    }

    if (!_hasMoreActivities || _isLoadingActivities) return;

    _isLoadingActivities = true;
    _activitiesError = null;
    notifyListeners();

    try {
      final data = await _securityService.getLoginActivities(page: _currentActivityPage);
      final List<dynamic> newActivities = data['data'];
      
      _activities.addAll(newActivities);
      
      if (newActivities.isEmpty || data['current_page'] >= data['last_page']) {
        _hasMoreActivities = false;
      } else {
        _currentActivityPage++;
      }
    } catch (e) {
      _activitiesError = e.toString();
    } finally {
      _isLoadingActivities = false;
      notifyListeners();
    }
  }
}
