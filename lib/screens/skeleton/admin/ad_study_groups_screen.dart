import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudyGroupsScreen extends ConsumerWidget {
  const AdStudyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Study Groups',
      description: 'Manage study groups',
      category: 'Academic',
      icon: Icons.group_work,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'study_groups',
    );
  }
}
