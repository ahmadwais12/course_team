import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionManager {
  static final instance = SessionManager._();
  SessionManager._();

  final _supabase = Supabase.instance.client;
  DateTime? _lastActivity;
  static const _sessionTimeout = Duration(minutes: 30);

  // Track activity
  void trackActivity() {
    _lastActivity = DateTime.now();
  }

  // Check if session is valid
  bool isSessionValid() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) < _sessionTimeout;
  }

  // Refresh session
  Future<void> refreshSession() async {
    try {
      await _supabase.auth.refreshSession();
      trackActivity();
    } catch (e) {
      await logout();
    }
  }

  // Logout
  Future<void> logout() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('user_sessions').update({
        'logged_out_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId).isFilter('logged_out_at', null);
    }

    await _supabase.auth.signOut();
    _lastActivity = null;
  }

  // Create session record
  Future<void> createSession(String deviceInfo) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('user_sessions').insert({
      'user_id': userId,
      'device_info': deviceInfo,
      'logged_in_at': DateTime.now().toIso8601String(),
      'ip_address': 'unknown', // Get from request in production
    });
    trackActivity();
  }

  // Get active sessions
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final userId = _supabase.auth.currentUser!.id;
    return List<Map<String, dynamic>>.from(
      await _supabase
          .from('user_sessions')
          .select('*')
          .eq('user_id', userId)
          .isFilter('logged_out_at', null)
          .order('logged_in_at', ascending: false),
    );
  }

  // Revoke session
  Future<void> revokeSession(String sessionId) async {
    await _supabase.from('user_sessions').update({
      'logged_out_at': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);
  }
}

// Provider for session state
final sessionProvider = StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(SessionState.initial());

  void updateActivity() {
    SessionManager.instance.trackActivity();
    state = SessionState(isValid: true, lastActivity: DateTime.now());
  }

  Future<void> logout() async {
    await SessionManager.instance.logout();
    state = SessionState.initial();
  }
}

class SessionState {
  final bool isValid;
  final DateTime? lastActivity;

  SessionState({required this.isValid, this.lastActivity});

  factory SessionState.initial() => SessionState(isValid: false);
}
