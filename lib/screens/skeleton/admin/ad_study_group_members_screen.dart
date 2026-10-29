import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdStudyGroupMembersScreen extends ConsumerWidget {
  const AdStudyGroupMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Study Group Members',
      description: 'Manage study group membership',
      category: 'Academic',
      icon: Icons.group_add,
      accentColor: const Color(0xFFF97316),
      tableName: 'study_group_members',
    );
  }
}
