import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCourseResourcesScreen extends ConsumerWidget {
  const AdCourseResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Course Resources',
      description: 'Manage course resources',
      category: 'Academic',
      icon: Icons.folder,
      accentColor: const Color(0xFF5B21B6),
      tableName: 'course_resources',
    );
  }
}
