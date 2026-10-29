import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCourseApplicationsScreen extends ConsumerWidget {
  const AdCourseApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Course Applications',
      description: 'Manage course applications',
      category: 'Admissions',
      icon: Icons.app_registration,
      accentColor: const Color(0xFF10B981),
      tableName: 'course_applications',
    );
  }
}
