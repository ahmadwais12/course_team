import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class MtMaintenanceTasksScreen extends ConsumerWidget {
  const MtMaintenanceTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Maintenance Tasks',
      description: 'Track maintenance task completion',
      category: 'Maintenance',
      icon: Icons.checklist,
      accentColor: const Color(0xFFF97316),
      tableName: 'maintenance_tasks',
    );
  }
}
