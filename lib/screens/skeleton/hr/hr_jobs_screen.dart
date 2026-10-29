import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrJobsScreen extends ConsumerWidget {
  const HrJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Jobs',
      description: 'Manage job positions',
      category: 'Recruitment',
      icon: Icons.work,
      accentColor: const Color(0xFF6366F1),
      tableName: 'jobs',
    );
  }
}
