import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaReportTemplatesScreen extends ConsumerWidget {
  const SaReportTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Report Templates',
      description: 'Manage report templates',
      category: 'Reports',
      icon: Icons.description,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'report_templates',
    );
  }
}
