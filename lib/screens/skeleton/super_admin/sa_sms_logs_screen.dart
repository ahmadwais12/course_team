import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaSmsLogsScreen extends ConsumerWidget {
  const SaSmsLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'SMS Logs',
      description: 'View sent SMS history',
      category: 'Monitoring',
      icon: Icons.sms,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'sms_logs',
    );
  }
}
