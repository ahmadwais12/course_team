import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaReportSchedulesScreen extends ConsumerWidget {
  const SaReportSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Report Schedules',
      description: 'Schedule automated reports',
      category: 'Reports',
      icon: Icons.schedule,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'report_schedules',
    );
  }
}
