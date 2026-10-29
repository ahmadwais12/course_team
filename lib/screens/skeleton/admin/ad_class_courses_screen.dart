import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdClassCoursesScreen extends ConsumerWidget {
  const AdClassCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Class-Course Assignments',
      description: 'Assign courses to classes',
      category: 'Academic',
      icon: Icons.class_outlined,
      accentColor: const Color(0xFF4C1D95),
      tableName: 'class_courses',
    );
  }
}
