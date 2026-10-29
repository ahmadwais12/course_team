import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaNotificationQueueScreen extends ConsumerWidget {
  const SaNotificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Notification Queue',
      description: 'View queued notifications',
      category: 'Communication',
      icon: Icons.queue,
      accentColor: const Color(0xFFA855F7),
      tableName: 'notification_queue',
    );
  }
}
