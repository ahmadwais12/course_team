import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaNotificationTemplatesScreen extends ConsumerWidget {
  const SaNotificationTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Notification Templates',
      description: 'Manage notification templates',
      category: 'Communication',
      icon: Icons.email,
      accentColor: const Color(0xFF6366F1),
      tableName: 'notification_templates',
    );
  }
}
