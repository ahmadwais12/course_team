import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnConversationsScreen extends ConsumerWidget {
  const GnConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Conversations',
      description: 'Manage conversations',
      category: 'Communication',
      icon: Icons.forum,
      accentColor: const Color(0xFF6366F1),
      tableName: 'conversations',
    );
  }
}
