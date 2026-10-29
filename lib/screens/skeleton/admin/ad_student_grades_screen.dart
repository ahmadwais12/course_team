import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentGradesScreen extends ConsumerWidget {
  const AdStudentGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Grades',
      description: 'Manage individual student grades',
      category: 'Academic',
      icon: Icons.assessment,
      accentColor: const Color(0xFF10B981),
      tableName: 'student_grades',
    );
  }
}
