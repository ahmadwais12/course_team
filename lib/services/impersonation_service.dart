import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/services/secure_storage_service.dart';
import 'package:course_emis/utils/app_logger.dart';

/// Holds the full impersonation context (dual identity).
class ImpersonationSession {
  final String sessionId;
  final String superAdminId;
  final String superAdminRole;
  final String targetUserId;
  final String? targetRole;
  final String? targetName;
  final String? targetEmail;
  final String? tenantId;
  final DateTime expiresAt;
  final String? reason;
  final DateTime startedAt;

  const ImpersonationSession({
    required this.sessionId,
    required this.superAdminId,
    this.superAdminRole = 'super_admin',
    required this.targetUserId,
    this.targetRole,
    this.targetName,
    this.targetEmail,
    this.tenantId,
    required this.expiresAt,
    this.reason,
    required this.startedAt,
  });

  bool get isActive => DateTime.now().isBefore(expiresAt);

  int get remainingSeconds => expiresAt.difference(DateTime.now()).inSeconds;

  factory ImpersonationSession.fromJson(Map<String, dynamic> j) {
    return ImpersonationSession(
      sessionId: j['sessionId'] as String,
      superAdminId: j['superAdminId'] as String,
      superAdminRole: (j['superAdminRole'] as String?) ?? 'super_admin',
      targetUserId: j['targetUserId'] as String,
      targetRole: j['targetRole'] as String?,
      targetName: j['targetName'] as String?,
      targetEmail: j['targetEmail'] as String?,
      tenantId: j['tenantId'] as String?,
      expiresAt: DateTime.parse(j['expiresAt'] as String),
      reason: j['reason'] as String?,
      startedAt: DateTime.parse(j['startedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'superAdminId': superAdminId,
        'superAdminRole': superAdminRole,
        'targetUserId': targetUserId,
        'targetRole': targetRole,
        'targetName': targetName,
        'targetEmail': targetEmail,
        'tenantId': tenantId,
        'expiresAt': expiresAt.toIso8601String(),
        'reason': reason,
        'startedAt': startedAt.toIso8601String(),
      };
}

/// Service for the "Login As" / Force Login feature (Super Admin only).
///
/// The underlying Supabase auth user stays the super admin for security
/// accountability (per the dual-identity model). While impersonating, the app
/// stores a short-lived session descriptor in secure storage and the UI reads
/// the target user's role/id/tenant from [session] so every screen behaves
/// like the impersonated user. Exiting restores the super admin view.
class ImpersonationService {
  final _client = Supabase.instance.client;
  final SecureStorageService _secureStorage;

  ImpersonationService(this._secureStorage);

  /// True if there is an active (non-expired) impersonation session locally.
  Future<bool> hasActiveSession() async {
    final session = await getSession();
    return session != null && session.isActive;
  }

  Future<ImpersonationSession?> getSession() async {
    final stored = await _secureStorage.readSession();
    if (stored == null || stored.isEmpty) return null;
    try {
      final json = jsonDecode(stored);
      if (json is! Map<String, dynamic>) return null;
      return ImpersonationSession.fromJson(json);
    } catch (e) {
      AppLogger.w('Failed to decode impersonation session', tag: 'Impersonation');
      return null;
    }
  }

  /// Start impersonating [targetUserId]. Only the current user (must be super
  /// admin) can invoke — enforced server side by the RLS policy.
  Future<ImpersonationSession> startImpersonation({
    required String targetUserId,
    String? reason,
  }) async {
    final admin = _client.auth.currentUser;
    if (admin == null) {
      throw StateError('Not authenticated');
    }

    // Load target profile once (used for validation + banner display).
    final target = await _client
        .from('users')
        .select('id, full_name, email, role, tenant_id, is_active')
        .eq('id', targetUserId)
        .maybeSingle();

    if (target == null) {
      throw StateError('Target user not found');
    }
    if (target['role'] == 'super_admin') {
      throw StateError('Cannot impersonate another super admin');
    }
    if (target['is_active'] == false) {
      throw StateError('Target user is inactive');
    }

    // Server side: create session via RPC start_impersonation() if deployed,
    // otherwise fall back to a guarded table insert.
    final row = await _startViaRpc(target, reason);
    final session = _normalizeSession(row, admin.id, target);

    await _secureStorage.writeSession(session.toJson());
    await _writeAuditLog(session, 'login_as', reason);
    return session;
  }

  Future<Map<String, dynamic>> _startViaRpc(
      Map<String, dynamic> target, String? reason) async {
    try {
      final data = await _client.rpc('start_impersonation', params: {
        'p_target_user_id': target['id'],
        'p_reason': reason,
      });
      if (data != null && data is Map) return Map<String, dynamic>.from(data);
      throw StateError('RPC returned no session');
    } catch (e) {
      // RPC may not be deployed yet — fall back to direct inserts.
      AppLogger.w('start_impersonation RPC failed, falling back to inserts: $e',
          tag: 'Impersonation');
      return _fallbackInserts(target, reason);
    }
  }

  /// Fallback that performs the same server-side steps using normal Supabase
  /// table writes. Used only until the RPC is deployed.
  Future<Map<String, dynamic>> _fallbackInserts(
      Map<String, dynamic> target, String? reason) async {
    final admin = _client.auth.currentUser!;

    final expires = DateTime.now().add(const Duration(minutes: 30));
    final insert = await _client.from('impersonation_sessions').insert({
      'super_admin_id': admin.id,
      'super_admin_role': 'super_admin',
      'target_user_id': target['id'],
      'target_role': target['role'],
      'tenant_id': target['tenant_id'],
      'status': 'active',
      'expires_at': expires.toIso8601String(),
      'reason': reason,
    }).select().single();

    return Map<String, dynamic>.from(insert);
  }

  ImpersonationSession _normalizeSession(
      Map<String, dynamic> row, String adminId, Map<String, dynamic> target) {
    return ImpersonationSession(
      sessionId:
          row['id']?.toString() ?? '${DateTime.now().microsecondsSinceEpoch}',
      superAdminId: adminId,
      superAdminRole: (row['super_admin_role'] as String?) ?? 'super_admin',
      targetUserId: target['id']?.toString() ?? '',
      targetRole: (row['target_role'] as String?) ?? target['role']?.toString(),
      targetName: target['full_name']?.toString(),
      targetEmail: target['email']?.toString(),
      tenantId: (row['tenant_id']?.toString()) ?? target['tenant_id']?.toString(),
      expiresAt: DateTime.parse(
          (row['expires_at'] ?? DateTime.now().add(const Duration(minutes: 30))).toString()),
      reason: row['reason'] as String?,
      startedAt: (row['started_at'] as String?)?.let(DateTime.parse)?.toLocal() ??
          DateTime.now(),
    );
  }

  /// End the current impersonation: mark the session ended + audit log.
  Future<void> exitImpersonation() async {
    final session = await getSession();
    if (session != null) {
      try {
        await _client
            .from('impersonation_sessions')
            .update({
              'status': 'ended',
              'ended_at': DateTime.now().toIso8601String(),
              'ended_by': session.superAdminId,
            })
            .eq('id', session.sessionId);
        await _writeAuditLog(session, 'exit', null);
      } catch (e) {
        AppLogger.w('Failed to end impersonation session server-side: $e',
            tag: 'Impersonation');
      }
    }
    await _secureStorage.clearSession();
  }

  /// Force end on expiry/auto-restore when the server says the session is gone.
  Future<void> clearImpersonation() async {
    await _secureStorage.clearSession();
  }

  Future<void> _writeAuditLog(
      ImpersonationSession s, String action, String? reason) async {
    try {
      await _client.from('impersonation_log').insert({
        'session_id': s.sessionId,
        'tenant_id': s.tenantId,
        'actor_id': s.superAdminId,
        'target_user_id': s.targetUserId,
        'target_role': s.targetRole,
        'action': action,
        'details': {
          if (reason != null) 'reason': reason,
          'super_admin_id': s.superAdminId,
          'target_role': s.targetRole,
        },
      });
    } catch (e) {
      AppLogger.w('Failed to write impersonation_log: $e',
          tag: 'Impersonation');
    }
  }

  /// Fetch the audit trail of impersonation activity (super admin view).
  Future<List<Map<String, dynamic>>> getHistory() async {
    final rows = await _client
        .from('impersonation_log')
        .select(
            '*, actor:actor_id(id, full_name, email), target:target_user_id(id, full_name, email)')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(rows);
  }
}

extension _Let<T> on T {
  R? let<R>(R? Function(T) block) => block(this);
}

final impersonationServiceProvider = Provider((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ImpersonationService(secureStorage);
});