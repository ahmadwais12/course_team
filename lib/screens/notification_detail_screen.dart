import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/notification.dart';
import 'package:course_emis/providers/notification_provider.dart';
import 'package:course_emis/widgets/modern_ui.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  ConsumerState<NotificationDetailScreen> createState() => _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends ConsumerState<NotificationDetailScreen> {
  bool _deleted = false;

  IconData _getIcon(NotificationType type) {
    switch (type) {
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

  Color _getColor(NotificationType type) {
    switch (type) {
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

  String _typeLabel(NotificationType type, WidgetRef ref) {
    switch (type) {
      case NotificationType.grade: return t(LAll.all_type_grade, ref);
      case NotificationType.discount: return t(LAll.all_type_discount, ref);
      case NotificationType.payment: return t(LAll.all_type_payment, ref);
      case NotificationType.salary: return t(LAll.all_type_salary, ref);
      case NotificationType.announcement: return t(LAll.all_announcement, ref);
      case NotificationType.system: return t(LAll.all_type_system, ref);
      case NotificationType.attendance: return t(LAll.all_type_attendance, ref);
      case NotificationType.hr: return t(LAll.all_hr, ref);
      case NotificationType.academic: return t(LAll.all_academic, ref);
      default: return t(LAll.all_type_general, ref);
    }
  }

  String _priorityLabel(NotificationPriority priority, WidgetRef ref) {
    switch (priority) {
      case NotificationPriority.urgent: return t(LAll.all_urgent, ref);
      case NotificationPriority.high: return t(LAll.all_high, ref);
      case NotificationPriority.normal: return t(LAll.all_normal, ref);
      case NotificationPriority.low: return t(LAll.all_low, ref);
    }
  }

  Color _priorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent: return Colors.red;
      case NotificationPriority.high: return Colors.orange;
      case NotificationPriority.normal: return Colors.grey;
      case NotificationPriority.low: return Colors.blueGrey;
    }
  }

  Future<void> _openAction(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tt(LAll.all_failed_to_open_url_x, ref, [url]))),
      );
    }
  }

  Future<void> _delete(AppNotification n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_notification, ref)),
        content: Text('${t(LAll.all_are_you_sure_you_want_to_delete, ref)} "${n.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t(L.cancel, ref)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(notificationNotifierProvider.notifier).deleteNotification(n.id);
      if (mounted) {
        setState(() => _deleted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_notification_details, ref)),
        elevation: 0,
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          final notification = notifications.where((n) => n.id == widget.notificationId).firstOrNull;
          if (_deleted || notification == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(t(L.noData, ref), style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(t(L.back, ref)),
                  ),
                ],
              ),
            );
          }

          final color = _getColor(notification.type);
          final priorityColor = _priorityColor(notification.priority);
          final priorityLabel = _priorityLabel(notification.priority, ref);

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ModernCard(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(_getIcon(notification.type), color: color, size: 32),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: priorityColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: priorityColor),
                                          ),
                                          child: Text(
                                            priorityLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: priorityColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            _typeLabel(notification.type, ref),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: color,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                                          size: 18,
                                          color: notification.isRead ? Colors.green : Colors.orange,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      notification.title,
                                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${notification.createdAt.day}/${notification.createdAt.month}/${notification.createdAt.year}  ${_twoDigits(notification.createdAt.hour)}:${_twoDigits(notification.createdAt.minute)}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          if (notification.body != null && notification.body!.isNotEmpty) ...[
                            Text(
                              notification.body!,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (notification.message.isNotEmpty) ...[
                            Text(
                              notification.message,
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (notification.actionUrl != null && notification.actionUrl!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _openAction(notification.actionUrl),
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: Text(t(LAll.all_open_action, ref)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ref.read(notificationNotifierProvider.notifier).markAsRead(notification.id);
                                  },
                                  icon: const Icon(Icons.mark_email_read, size: 18),
                                  label: Text(t(LAll.all_mark_read, ref)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ref.read(notificationNotifierProvider.notifier).markAsUnread(notification.id);
                                  },
                                  icon: const Icon(Icons.mark_email_unread, size: 18),
                                  label: Text(t(LAll.all_mark_unread, ref)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _delete(notification),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: Text(t(LAll.all_delete_notification, ref)),
                            ),
                          ),
                          if (notification.data != null && notification.data!.isNotEmpty) ...[
                            const Divider(height: 32),
                            Text(
                              t(LColumn.details, ref),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ..._buildDataRows(notification.data!, theme),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${t(LGen.errorDetails, ref)}: $err')),
      ),
    );
  }

  List<Widget> _buildDataRows(Map<String, dynamic> data, ThemeData theme) {
    return data.entries.map((e) {
      final value = e.value.toString();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                e.key,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
