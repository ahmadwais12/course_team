import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrEmployeeLeavesScreen extends ConsumerWidget {
  const HrEmployeeLeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Employee Leaves',
      description: 'Manage employee leave records',
      category: 'HR',
      icon: Icons.event_busy,
      accentColor: const Color(0xFFE11D48),
      tableName: 'employee_leaves',
    );
  }
}
