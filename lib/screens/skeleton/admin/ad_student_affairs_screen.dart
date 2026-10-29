import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudentAffairsScreen extends ConsumerWidget {
  const AdStudentAffairsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Affairs',
      description: 'Manage student affairs records',
      category: 'Academic',
      icon: Icons.diversity_3,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'student_affairs',
    );
  }
}
