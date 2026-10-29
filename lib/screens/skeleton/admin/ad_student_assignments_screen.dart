import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentAssignmentsScreen extends ConsumerWidget {
  const AdStudentAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Assignments',
      description: 'Manage student assignments',
      category: 'Academic',
      icon: Icons.assignment,
      accentColor: const Color(0xFF6366F1),
      tableName: 'student_assignments',
    );
  }
}
