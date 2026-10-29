import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class StScheduleScreen extends ConsumerWidget {
  const StScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'My Schedule',
      description: 'View class schedule',
      category: 'Academic',
      icon: Icons.schedule,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'student_schedules',
    );
  }
}
