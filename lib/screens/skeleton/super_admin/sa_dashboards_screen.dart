import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaDashboardsScreen extends ConsumerWidget {
  const SaDashboardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Platform Dashboards',
      description: 'Configure platform dashboards',
      category: 'System',
      icon: Icons.dashboard_customize,
      accentColor: const Color(0xFF6366F1),
      tableName: 'dashboards',
    );
  }
}
