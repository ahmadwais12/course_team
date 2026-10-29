import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class StLeavesScreen extends ConsumerWidget {
  const StLeavesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'My Leaves',
      description: 'Submit and view leave requests',
      category: 'Academic',
      icon: Icons.event_busy,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'student_leaves',
    );
  }
}
