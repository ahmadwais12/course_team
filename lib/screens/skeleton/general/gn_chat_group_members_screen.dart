import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnChatGroupMembersScreen extends ConsumerWidget {
  const GnChatGroupMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Chat Group Members',
      description: 'Manage chat group members',
      category: 'Communication',
      icon: Icons.people,
      accentColor: const Color(0xFFA855F7),
      tableName: 'chat_group_members',
    );
  }
}
