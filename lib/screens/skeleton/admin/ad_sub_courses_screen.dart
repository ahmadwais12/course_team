import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdSubCoursesScreen extends ConsumerWidget {
  const AdSubCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Sub-Courses',
      description: 'Manage sub-courses within courses',
      category: 'Academic',
      icon: Icons.book_outlined,
      accentColor: const Color(0xFFA855F7),
      tableName: 'sub_courses',
    );
  }
}
