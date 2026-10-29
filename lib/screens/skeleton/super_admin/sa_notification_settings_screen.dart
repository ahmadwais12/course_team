import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaNotificationSettingsScreen extends ConsumerWidget {
  const SaNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Notification Settings',
      description: 'Configure global notification settings',
      category: 'Communication',
      icon: Icons.settings_applications,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'notification_settings',
    );
  }
}
