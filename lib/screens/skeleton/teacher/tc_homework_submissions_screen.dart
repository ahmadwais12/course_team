import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TcHomeworkSubmissionsScreen extends ConsumerWidget {
  const TcHomeworkSubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Homework Submissions',
      description: 'Review student homework submissions',
      category: 'Academic',
      icon: Icons.assignment_turned_in,
      accentColor: const Color(0xFF10B981),
      tableName: 'homework_submissions',
    );
  }
}
