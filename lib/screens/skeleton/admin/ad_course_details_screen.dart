import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCourseDetailsScreen extends ConsumerWidget {
  const AdCourseDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Course Details',
      description: 'Detailed course information',
      category: 'Academic',
      icon: Icons.info_outline,
      accentColor: const Color(0xFF6D28D9),
      tableName: 'course_details',
    );
  }
}
