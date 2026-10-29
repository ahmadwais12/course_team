import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCourseContentScreen extends ConsumerWidget {
  const AdCourseContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Course Content',
      description: 'Manage course content and materials',
      category: 'Academic',
      icon: Icons.content_paste,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'course_content',
    );
  }
}
