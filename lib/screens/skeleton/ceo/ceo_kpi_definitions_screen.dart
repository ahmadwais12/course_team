import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class CeoKpiDefinitionsScreen extends ConsumerWidget {
  const CeoKpiDefinitionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'KPI Definitions',
      description: 'Define key performance indicators',
      category: 'Executive',
      icon: Icons.speed,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'kpi_definitions',
    );
  }
}
