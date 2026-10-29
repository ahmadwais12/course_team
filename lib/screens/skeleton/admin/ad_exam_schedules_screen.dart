import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdExamSchedulesScreen extends ConsumerWidget {
  const AdExamSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Exam Schedules',
      description: 'Manage exam date, time, and room schedules',
      category: 'Academics',
      icon: Icons.schedule,
      accentColor: const Color(0xFFEF4444),
      tableName: 'exam_schedules',
    );
  }
}
