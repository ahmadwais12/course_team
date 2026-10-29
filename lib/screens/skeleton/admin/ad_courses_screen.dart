import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdCoursesScreen extends ConsumerWidget {
  const AdCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Courses',
      description: 'Manage course catalog',
      category: 'Academic',
      icon: Icons.book,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'courses',
    );
  }
}
