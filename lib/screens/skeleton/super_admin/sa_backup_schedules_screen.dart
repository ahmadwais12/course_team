import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaBackupSchedulesScreen extends ConsumerWidget {
  const SaBackupSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Backup Schedules',
      description: 'Schedule automated backups',
      category: 'System',
      icon: Icons.schedule,
      accentColor: const Color(0xFF10B981),
      tableName: 'backup_schedules',
    );
  }
}
