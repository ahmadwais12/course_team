import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdAdminCourseAssignmentsScreen extends ConsumerWidget {
  const AdAdminCourseAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Admin Course Assignments',
      description: 'Assign courses to admins',
      category: 'Academic',
      icon: Icons.assignment_ind,
      accentColor: const Color(0xFFEC4899),
      tableName: 'admin_course_assignments',
    );
  }
}
