import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrStaffTasksScreen extends ConsumerWidget {
  const HrStaffTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Staff Tasks',
      description: 'Assign and track staff tasks',
      category: 'HR',
      icon: Icons.task,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'staff_tasks',
    );
  }
}
