import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class StProgressScreen extends ConsumerWidget {
  const StProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'My Progress',
      description: 'View academic progress',
      category: 'Academic',
      icon: Icons.trending_up,
      accentColor: const Color(0xFF6366F1),
      tableName: 'student_progress',
    );
  }
}
