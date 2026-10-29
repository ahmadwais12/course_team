import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaActivityLogsScreen extends ConsumerWidget {
  const SaActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Activity Logs',
      description: 'View system activity logs',
      category: 'Monitoring',
      icon: Icons.timeline,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'activity_logs',
    );
  }
}
