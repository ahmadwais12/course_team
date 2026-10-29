import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdClassSubjectsScreen extends ConsumerWidget {
  const AdClassSubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Class-Subject Assignments',
      description: 'Assign subjects to classes',
      category: 'Academic',
      icon: Icons.subject,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'class_subjects',
    );
  }
}
