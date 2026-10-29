import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:course_emis/models/notification.dart';

typedef NotificationTapCallback = void Function(RemoteMessage message);

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  bool _initialized = false;
  NotificationTapCallback? onTap;

  RealtimeChannel? _realtimeChannel;
  final _notificationController =
      StreamController<List<AppNotification>>.broadcast();
  List<AppNotification> _notifCache = [];

  Stream<List<AppNotification>> get notificationStream =>
      _notificationController.stream;

  int get unreadCount => _notifCache.where((n) => !n.isRead).length;

  Future<void> init({NotificationTapCallback? onTap}) async {
    if (_initialized) {
      debugPrint('[NotificationService] init — already initialized, skipping');
      return;
    }
    debugPrint('[NotificationService] init — initializing Firebase...');
    this.onTap = onTap;
    await Firebase.initializeApp();
    final messaging = FirebaseMessaging.instance;
    final permission = await messaging.requestPermission();
    debugPrint('[NotificationService] init — permission granted: ${permission.authorizationStatus}');
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);
    final token = await messaging.getToken();
    debugPrint('[NotificationService] init — FCM token obtained: ${token != null}');
    _initialized = true;
    debugPrint('[NotificationService] init — complete');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[NotificationService] _onForegroundMessage — title="${message.notification?.title}", body="${message.notification?.body}"');
    debugPrint('[NotificationService] _onForegroundMessage — data: $message.data');
    _storeLocal(message);
    final navigatorKey = GlobalKey<NavigatorState>();
    final context = navigatorKey.currentContext;
    if (context != null) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title: $body')),
      );
    }
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('[NotificationService] _onMessageOpenedApp — title="${message.notification?.title}"');
    if (onTap != null) {
      debugPrint('[NotificationService] _onMessageOpenedApp — invoking onTap callback');
      onTap!(message);
    }
  }

  Future<void> _storeLocal(RemoteMessage message) async {
    debugPrint('[NotificationService] _storeLocal — storing notification locally...');
    final prefs = await SharedPreferences.getInstance();
    final key = 'app_notifications';
    final list = prefs.getStringList(key) ?? [];
    final id = const Uuid().v4();
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final notificationType = message.data['type'] ?? 'general';
    final data = {
      'id': id,
      'userId': message.data['userId'] ?? '',
      'type': notificationType,
      'title': title,
      'message': body,
      'isRead': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    list.insert(0, jsonEncode(data));
    await prefs.setStringList(key, list);
    debugPrint('[NotificationService] _storeLocal — saved to SharedPreferences, total stored: ${list.length}');

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? message.data['userId'] ?? '';
      if (userId.isNotEmpty) {
        debugPrint('[NotificationService] _storeLocal — inserting into Supabase notifications for userId=$userId');
        await Supabase.instance.client.from('notifications').insert({
          'user_id': userId,
          'title': title,
          'body': body,
          'data': message.data.isNotEmpty ? jsonEncode(message.data) : null,
          'type': notificationType,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('[NotificationService] _storeLocal — Supabase insert succeeded');
      }
    } catch (e) {
      debugPrint('[NotificationService] _storeLocal — Supabase insert error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    debugPrint('[NotificationService] getNotifications — userId=$userId');
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      debugPrint('[NotificationService] getNotifications — fetched ${data.length} notifications from Supabase');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[NotificationService] getNotifications — Supabase error, falling back to local: $e');
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('app_notifications') ?? [];
      debugPrint('[NotificationService] getNotifications — loaded ${list.length} from local storage');
      return list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    debugPrint('[NotificationService] markAsRead — notificationId=$notificationId');
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      debugPrint('[NotificationService] markAsRead — success');
    } catch (e) {
      debugPrint('[NotificationService] markAsRead — error: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
    } catch (_) {}
  }

  void subscribeToNotifications() {
    debugPrint('[NotificationService] subscribeToNotifications — subscribing...');
    _realtimeChannel?.unsubscribe();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[NotificationService] subscribeToNotifications — no user logged in, aborting');
      return;
    }
    debugPrint('[NotificationService] subscribeToNotifications — userId=$userId');

    _loadInitialNotifications(userId);

    _realtimeChannel = Supabase.instance.client
        .channel('app-notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final uid = Supabase.instance.client.auth.currentUser?.id;
            final eventType = payload.eventType;
            debugPrint('[NotificationService] realtime event — type=$eventType, row_id=${payload.newRecord['id'] ?? payload.oldRecord['id']}');
            if (uid == null) return;
            if (eventType == PostgresChangeEvent.insert) {
              final row = payload.newRecord;
              debugPrint('[NotificationService] realtime INSERT — row userId=${row['user_id']}, current uid=$uid');
              if (row['user_id'] == uid) {
                _notifCache.insert(0, _mapRow(row));
                _notificationController.add(List.from(_notifCache));
                debugPrint('[NotificationService] realtime INSERT — added to cache, total=${_notifCache.length}');
              }
            } else if (eventType == PostgresChangeEvent.update) {
              final row = payload.newRecord;
              if (row['user_id'] == uid) {
                final idx = _notifCache.indexWhere((n) => n.id == row['id']);
                if (idx != -1) {
                  _notifCache[idx] = _mapRow(row);
                  _notificationController.add(List.from(_notifCache));
                  debugPrint('[NotificationService] realtime UPDATE — updated idx=$idx');
                } else {
                  debugPrint('[NotificationService] realtime UPDATE — id not found in cache, ignoring');
                }
              }
            } else if (eventType == PostgresChangeEvent.delete) {
              final row = payload.oldRecord;
              _notifCache.removeWhere((n) => n.id == row['id']);
              _notificationController.add(List.from(_notifCache));
              debugPrint('[NotificationService] realtime DELETE — removed, total=${_notifCache.length}');
            }
          },
        )
        .subscribe();
    debugPrint('[NotificationService] subscribeToNotifications — subscription active');
  }

  void unsubscribeFromNotifications() {
    debugPrint('[NotificationService] unsubscribeFromNotifications — unsubscribing...');
    if (_realtimeChannel != null) {
      Supabase.instance.client.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
      debugPrint('[NotificationService] unsubscribeFromNotifications — done');
    } else {
      debugPrint('[NotificationService] unsubscribeFromNotifications — no active channel');
    }
  }

  Future<void> _loadInitialNotifications(String userId) async {
    debugPrint('[NotificationService] _loadInitialNotifications — fetching notifications for $userId...');
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      _notifCache =
          data.map<AppNotification>((row) => _mapRow(row)).toList();
      _notificationController.add(List.from(_notifCache));
      debugPrint('[NotificationService] _loadInitialNotifications — loaded ${_notifCache.length} notifications');
    } catch (e) {
      debugPrint('[NotificationService] _loadInitialNotifications — error: $e');
    }
  }

  AppNotification _mapRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      tenantId: row['tenant_id'] as String?,
      type: NotificationType.values.firstWhere(
        (e) => e.name == (row['type'] as String? ?? 'general'),
        orElse: () => NotificationType.general,
      ),
      title: row['title'] as String? ?? '',
      message: row['body'] as String? ?? row['message'] as String? ?? '',
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

  void disposeNotifications() {
    unsubscribeFromNotifications();
    _notificationController.close();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();
  final key = 'app_notifications';
  final list = prefs.getStringList(key) ?? [];
  final id = const Uuid().v4();
  final title = message.notification?.title ?? 'Notification';
  final body = message.notification?.body ?? '';
  final data = {
    'id': id,
    'userId': message.data['userId'] ?? '',
    'type': 'general',
    'title': title,
    'message': body,
    'isRead': false,
    'createdAt': DateTime.now().toIso8601String(),
  };
  list.insert(0, jsonEncode(data));
  await prefs.setStringList(key, list);
}
