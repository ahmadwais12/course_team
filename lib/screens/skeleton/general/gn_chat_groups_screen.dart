import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnChatGroupsScreen extends ConsumerWidget {
  const GnChatGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Chat Groups',
      description: 'Manage chat groups',
      category: 'Communication',
      icon: Icons.group,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'chat_groups',
    );
  }
}
