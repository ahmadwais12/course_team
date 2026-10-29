import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentEnrollmentsScreen extends ConsumerWidget {
  const AdStudentEnrollmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Enrollments',
      description: 'Detailed enrollment records per student',
      category: 'Academic',
      icon: Icons.school,
      accentColor: const Color(0xFF6D28D9),
      tableName: 'student_enrollments',
    );
  }
}
