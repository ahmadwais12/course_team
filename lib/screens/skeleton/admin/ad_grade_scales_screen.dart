import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdGradeScalesScreen extends ConsumerWidget {
  const AdGradeScalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Grade Scales',
      description: 'Manage grade scales and grading rubrics',
      category: 'Academic',
      icon: Icons.grade,
      accentColor: const Color(0xFF10B981),
      tableName: 'grade_scales',
    );
  }
}
