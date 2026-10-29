import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class CeoKpiRecordsScreen extends ConsumerWidget {
  const CeoKpiRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'KPI Records',
      description: 'Track KPI measurement records',
      category: 'Executive',
      icon: Icons.analytics,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'kpi_records',
    );
  }
}
