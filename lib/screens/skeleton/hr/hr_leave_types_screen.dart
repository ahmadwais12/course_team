import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrLeaveTypesScreen extends ConsumerWidget {
  const HrLeaveTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Leave Types',
      description: 'Define leave types and policies',
      category: 'HR',
      icon: Icons.category,
      accentColor: const Color(0xFFF43F5E),
      tableName: 'leave_types',
    );
  }
}
