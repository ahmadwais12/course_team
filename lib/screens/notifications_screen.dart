import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/notification.dart';
import 'package:course_emis/providers/notification_provider.dart';
import 'package:course_emis/widgets/modern_ui.dart';
import 'package:course_emis/widgets/shimmer_loading.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  static const _pageSize = 10;

  String _filter = 'All';

  final _scrollCtl = ScrollController();
  int _visibleCount = _pageSize;
  bool _loadingMore = false;

  bool _canCompose() {
    final role = Supabase.instance.client.auth.currentUser
        ?.userMetadata?['role']?.toString().toLowerCase();
    return role != null &&
        ['super_admin', 'admin', 'academic_support', 'hr_manager'].contains(role);
  }

  List<AppNotification> _applyFilter(List<AppNotification> notifications) {
    switch (_filter) {
      case 'Unread':
        return notifications.where((n) => !n.isRead).toList();
      case 'Read':
        return notifications.where((n) => n.isRead).toList();
      default:
        return notifications;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollCtl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtl.hasClients) return;
    final position = _scrollCtl.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final current = ref.read(notificationStreamProvider).value;
    if (current == null) return;
    final filtered = _applyFilter(current);
    if (_visibleCount >= filtered.length) return;
    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _visibleCount += _pageSize;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationStreamProvider);

    debugPrint('[NotificationsScreen] build() — notificationsAsync state: ${notificationsAsync.isLoading ? "loading" : notificationsAsync.hasError ? "error: ${notificationsAsync.error}" : "data (${notificationsAsync.value?.length ?? 0} items)"}');

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LNav.notifications, ref)),
        elevation: 0,
        actions: [
          if (_canCompose())
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutesAll.notificationCompose),
                icon: const Icon(Icons.add_alert, size: 18),
                label: const Text('Compose'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(Icons.all_inclusive, t(LFilter.all, ref), 'All'),
                      const SizedBox(width: 8),
                      _buildFilterChip(Icons.mark_email_unread, t(LMessage.unread, ref), 'Unread'),
                      const SizedBox(width: 8),
                      _buildFilterChip(Icons.mark_email_read, 'Read', 'Read'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) {
                  debugPrint('[NotificationsScreen] data received — total=${notifications.length}, filter=$_filter');
                  final filtered = _applyFilter(notifications);
                  final visible = filtered.take(_visibleCount).toList();
                  debugPrint('[NotificationsScreen] after filter — filtered=${filtered.length}, visible=${visible.length}');

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(t(L.noData, ref), style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: _scrollCtl,
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length + (_loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index >= visible.length) {
                        return const _NotificationSkeletonCard();
                      }
                      final notification = visible[index];
                      debugPrint('[NotificationsScreen] rendering card #$index — id=${notification.id}, title=${notification.title}, isRead=${notification.isRead}');
                      return _EnhancedNotificationCard(
                        notification: notification,
                        onTap: () {
                          debugPrint('[NotificationsScreen] onTap — opening detail: id=${notification.id}');
                          if (!notification.isRead) {
                            ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
                          }
                          context.push('${AppRoutesAll.notificationDetailBase}/${notification.id}');
                        },
                      );
                    },
                  );
                },
                loading: () {
                  debugPrint('[NotificationsScreen] loading state');
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 8,
                    itemBuilder: (_, __) =>
                        const Padding(padding: EdgeInsets.only(bottom: 12), child: _NotificationSkeletonCard()),
                  );
                },
                error: (err, stack) {
                  debugPrint('[NotificationsScreen] error state — err=$err, stack=$stack');
                  return Center(child: Text('${t(LGen.errorDetails, ref)}: $err'));
                },
              ),
            ),
          ],
      ),
      ),
    ));
  }

  Widget _buildFilterChip(IconData icon, String label, String value) {
    final selected = _filter == value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fg = selected ? theme.colorScheme.onPrimary : (isDark ? Colors.white : Colors.black87);
    return ChoiceChip(
      selected: selected,
      onSelected: (_) {
        debugPrint('[NotificationsScreen] filter changed — previous=$_filter, new=$value');
        setState(() {
          _filter = value;
          _visibleCount = _pageSize;
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _NotificationSkeletonCard extends StatelessWidget {
  const _NotificationSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 180,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 140,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedNotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _EnhancedNotificationCard({required this.notification, required this.onTap});

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.grade: return Icons.grade;
      case NotificationType.discount: return Icons.discount;
      case NotificationType.payment: return Icons.payment;
      case NotificationType.salary: return Icons.attach_money;
      case NotificationType.announcement: return Icons.campaign;
      case NotificationType.system: return Icons.settings;
      case NotificationType.attendance: return Icons.calendar_today;
      case NotificationType.hr: return Icons.people;
      case NotificationType.academic: return Icons.school;
      default: return Icons.notifications;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.grade: return Colors.blue;
      case NotificationType.discount: return Colors.blue;
      case NotificationType.payment: return Colors.orange;
      case NotificationType.salary: return Colors.purple;
      case NotificationType.announcement: return Colors.red;
      case NotificationType.system: return Colors.grey;
      case NotificationType.attendance: return Colors.teal;
      case NotificationType.hr: return Colors.indigo;
      case NotificationType.academic: return Colors.green;
      default: return Colors.grey;
    }
  }

  String _priorityLabel() {
    switch (notification.priority) {
      case NotificationPriority.urgent: return 'URGENT';
      case NotificationPriority.high: return 'HIGH';
      case NotificationPriority.normal: return '';
      case NotificationPriority.low: return '';
    }
  }

  Color _priorityColor() {
    switch (notification.priority) {
      case NotificationPriority.urgent: return Colors.red;
      case NotificationPriority.high: return Colors.orange;
      case NotificationPriority.normal: return Colors.transparent;
      case NotificationPriority.low: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final priorityLabel = _priorityLabel();
    final priorityColor = _priorityColor();

    return ModernCard(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIcon(), color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (priorityLabel.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: priorityColor),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(fontSize: 10, color: priorityColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                      ),
                      if (notification.actionUrl != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'View Details →',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
      ),
      ),
    );
  }
}
