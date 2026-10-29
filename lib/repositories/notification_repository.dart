import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:course_emis/models/notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final _sb = Supabase.instance.client;
  List<AppNotification> _cache = [];
  RealtimeChannel? _channel;
  final _controller = StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get stream => _controller.stream;

  void subscribe() {
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[NotificationRepository] subscribe — no user logged in');
      return;
    }
    debugPrint('[NotificationRepository] subscribe — userId=$userId');
    unsubscribe();

    _loadInitial(userId);

    _channel = _sb
        .channel('notification-realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final uid = _sb.auth.currentUser?.id;
            if (uid == null) return;
            final eventType = payload.eventType;
            debugPrint('[NotificationRepository] realtime event — type=$eventType');
            if (eventType == PostgresChangeEvent.insert) {
              final row = payload.newRecord;
              if (row['user_id'] == uid) {
                final n = _mapNotification(row);
                // The row may already be in the cache (e.g. a manual
                // refresh/_loadInitial that ran after the insert). Dedupe.
                _cache.removeWhere((old) => old.id == n.id);
                _cache.insert(0, n);
                _controller.add(List.from(_cache));
                debugPrint('[NotificationRepository] INSERT — added, total=${_cache.length}');
              }
            } else if (eventType == PostgresChangeEvent.update) {
              final row = payload.newRecord;
              if (row['user_id'] == uid) {
                final idx = _cache.indexWhere((n) => n.id == row['id']);
                if (idx != -1) {
                  _cache[idx] = _mapNotification(row);
                  _controller.add(List.from(_cache));
                  debugPrint('[NotificationRepository] UPDATE — updated idx=$idx');
                }
              }
            } else if (eventType == PostgresChangeEvent.delete) {
              final row = payload.oldRecord;
              _cache.removeWhere((n) => n.id == row['id']);
              _controller.add(List.from(_cache));
              debugPrint('[NotificationRepository] DELETE — total=${_cache.length}');
            }
          },
        )
        .subscribe();
    debugPrint('[NotificationRepository] subscribe — realtime channel active');
  }

  void unsubscribe() {
    if (_channel != null) {
      debugPrint('[NotificationRepository] unsubscribe — removing channel');
      _sb.removeChannel(_channel!);
      _channel = null;
    }
  }

  /// Force a reload from the database and re-emit the list. Used after
  /// composing/sending notifications so the open screen updates
  /// immediately even if the realtime event has not arrived yet.
  Future<void> refresh() async {
    debugPrint('[NotificationRepository] refresh — reloading from DB...');
    final userId = _sb.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[NotificationRepository] refresh — no user logged in');
      return;
    }
    try {
      await _loadInitial(userId);
    } catch (e) {
      debugPrint('[NotificationRepository] refresh — error: $e');
    }
  }

  Future<void> _loadInitial(String userId) async {
    debugPrint('[NotificationRepository] _loadInitial — fetching for $userId...');
    try {
      final data = await _sb
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _cache = data.map<AppNotification>((row) => _mapNotification(row)).toList();
      _controller.add(List.from(_cache));
      debugPrint('[NotificationRepository] _loadInitial — loaded ${_cache.length} notifications');
    } catch (e) {
      debugPrint('[NotificationRepository] _loadInitial — error: $e');
    }
  }

  Future<List<AppNotification>> getAll() async {
    final userId = _sb.auth.currentUser?.id;
    debugPrint('[NotificationRepository] getAll — cache size=${_cache.length}, userId=$userId');
    if (_cache.isEmpty && userId != null) {
      debugPrint('[NotificationRepository] getAll — cache empty, loading from DB');
      await _loadInitial(userId);
    }
    return List.from(_cache);
  }

  Future<List<AppNotification>> getByUser(String userId) async {
    debugPrint('[NotificationRepository] getByUser — userId=$userId');
    final data = await _sb
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final notifications = data.map<AppNotification>((row) => _mapNotification(row)).toList();
    debugPrint('[NotificationRepository] getByUser — fetched ${notifications.length} notifications');
    return notifications;
  }

  Future<void> create(AppNotification notification) async {
    debugPrint('[NotificationRepository] create — id=${notification.id}, title=${notification.title}');
    await _sb.from('notifications').insert({
      'id': notification.id,
      'user_id': notification.userId,
      if (notification.tenantId != null) 'tenant_id': notification.tenantId,
      'type': notification.type.name,
      'title': notification.title,
      'body': notification.body ?? notification.message,
      'priority': notification.priority.name,
      if (notification.actionUrl != null) 'action_url': notification.actionUrl,
      if (notification.data != null) 'data': notification.data,
      'is_read': notification.isRead,
      'created_at': notification.createdAt.toIso8601String(),
    });
    _cache.insert(0, notification);
    _controller.add(List.from(_cache));
    debugPrint('[NotificationRepository] create — success, cache now ${_cache.length}');
  }

  Future<void> markAsRead(String id) async {
    debugPrint('[NotificationRepository] markAsRead — id=$id');
    await _sb.from('notifications').update({'is_read': true}).eq('id', id);
    final idx = _cache.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _cache[idx] = _cache[idx].copyWith(isRead: true);
      _controller.add(List.from(_cache));
      debugPrint('[NotificationRepository] markAsRead — updated cache idx=$idx');
    } else {
      debugPrint('[NotificationRepository] markAsRead — id not found in cache');
    }
  }

  Future<void> markAsUnread(String id) async {
    debugPrint('[NotificationRepository] markAsUnread — id=$id');
    await _sb.from('notifications').update({'is_read': false}).eq('id', id);
    final idx = _cache.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _cache[idx] = _cache[idx].copyWith(isRead: false);
      _controller.add(List.from(_cache));
      debugPrint('[NotificationRepository] markAsUnread — updated cache idx=$idx');
    } else {
      debugPrint('[NotificationRepository] markAsUnread — id not found in cache');
    }
  }

  Future<void> sendBulkNotification({
    required String title,
    required String body,
    required String type,
    required String priority,
    required String? actorId,
    required String? tenantId,
    required String targetType, // 'all', 'role', 'specific'
    List<String>? targetRoles,
    List<String>? targetUserIds,
  }) async {
    debugPrint('[NotificationRepository] sendBulkNotification — calling RPC...');
    debugPrint('[NotificationRepository]   title=$title, body=$body, type=$type, priority=$priority');
    debugPrint('[NotificationRepository]   actorId=$actorId, tenantId=$tenantId, targetType=$targetType');
    debugPrint('[NotificationRepository]   targetRoles=$targetRoles, targetUserIds=${targetUserIds?.length} users');
    await _sb.rpc('send_bulk_notification', params: {
      'p_title': title,
      'p_body': body,
      'p_type': type,
      'p_priority': priority,
      'p_actor_id': actorId,
      'p_tenant_id': tenantId,
      'p_target_type': targetType,
      'p_target_roles': targetRoles,
      'p_target_user_ids': targetUserIds,
    });
    debugPrint('[NotificationRepository] sendBulkNotification — RPC completed');
  }

  Future<void> delete(String id) async {
    debugPrint('[NotificationRepository] delete — id=$id');
    await _sb.from('notifications').delete().eq('id', id);
    _cache.removeWhere((n) => n.id == id);
    _controller.add(List.from(_cache));
    debugPrint('[NotificationRepository] delete — done, cache now ${_cache.length}');
  }

  void dispose() {
    debugPrint('[NotificationRepository] dispose — cleaning up');
    unsubscribe();
    _controller.close();
  }

  AppNotification _mapNotification(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      tenantId: row['tenant_id'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (row['type'] as String? ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      title: row['title'] as String? ?? '',
      message: row['message'] as String? ?? row['body'] as String? ?? '',
      body: row['body'] as String?,
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == (row['priority'] as String? ?? 'normal'),
        orElse: () => NotificationPriority.normal,
      ),
      actionUrl: row['action_url'] as String?,
      data: row['data'] as Map<String, dynamic>?,
      isRead: row['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
