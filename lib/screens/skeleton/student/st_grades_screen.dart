import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class StGradesScreen extends ConsumerWidget {
  const StGradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'My Grades',
      description: 'View grades and report cards',
      category: 'Academic',
      icon: Icons.grade,
      accentColor: const Color(0xFFA855F7),
      tableName: 'student_grades',
    );
  }
}
