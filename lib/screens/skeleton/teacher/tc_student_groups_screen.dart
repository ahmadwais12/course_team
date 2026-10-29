import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TcStudentGroupsScreen extends ConsumerWidget {
  const TcStudentGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Student Groups',
      description: 'Manage student groups',
      category: 'Academic',
      icon: Icons.group_work,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'student_groups',
    );
  }
}
