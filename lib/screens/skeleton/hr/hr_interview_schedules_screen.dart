import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrInterviewSchedulesScreen extends ConsumerWidget {
  const HrInterviewSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Interview Schedules',
      description: 'Schedule job interviews',
      category: 'Recruitment',
      icon: Icons.calendar_today,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'interview_schedules',
    );
  }
}
