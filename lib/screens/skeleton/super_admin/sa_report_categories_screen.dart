import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaReportCategoriesScreen extends ConsumerWidget {
  const SaReportCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Report Categories',
      description: 'Manage report categories',
      category: 'Reports',
      icon: Icons.category,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'report_categories',
    );
  }
}
