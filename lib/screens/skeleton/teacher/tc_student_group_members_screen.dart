import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TcStudentGroupMembersScreen extends ConsumerWidget {
  const TcStudentGroupMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Group Members',
      description: 'Manage student group memberships',
      category: 'Academic',
      icon: Icons.people,
      accentColor: const Color(0xFFA855F7),
      tableName: 'student_group_members',
    );
  }
}
