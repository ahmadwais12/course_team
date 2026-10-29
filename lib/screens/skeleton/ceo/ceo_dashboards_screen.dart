import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class CeoDashboardsScreen extends ConsumerWidget {
  const CeoDashboardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'CEO Dashboards',
      description: 'Executive dashboard configurations',
      category: 'Executive',
      icon: Icons.dashboard,
      accentColor: const Color(0xFF6366F1),
      tableName: 'ceo_dashboards',
    );
  }
}
