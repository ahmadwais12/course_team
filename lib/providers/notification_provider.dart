import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/notification.dart';
import 'package:course_emis/repositories/notification_repository.dart';

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final repo = NotificationRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final notificationNotifierProvider = StateNotifierProvider<NotificationNotifier,
    AsyncValue<List<AppNotification>>>((ref) {
  return NotificationNotifier(ref.read(notificationRepositoryProvider));
});

final notificationStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  repo.subscribe();
  return repo.stream;
});

class NotificationNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    debugPrint('[NotificationNotifier] loadNotifications — loading...');
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      debugPrint('[NotificationNotifier] loadNotifications — loaded ${data.length} notifications');
      state = AsyncValue.data(data);
    } catch (e, st) {
      debugPrint('[NotificationNotifier] loadNotifications — error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    debugPrint('[NotificationNotifier] addNotification — id=${notification.id}, title=${notification.title}');
    await _repository.create(notification);
    await loadNotifications();
  }

  Future<void> markAsRead(String id) async {
    debugPrint('[NotificationNotifier] markAsRead — id=$id');
    await _repository.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAsUnread(String id) async {
    debugPrint('[NotificationNotifier] markAsUnread — id=$id');
    await _repository.markAsUnread(id);
    await loadNotifications();
  }

  Future<void> deleteNotification(String id) async {
    debugPrint('[NotificationNotifier] deleteNotification — id=$id');
    await _repository.delete(id);
    await loadNotifications();
  }
}
