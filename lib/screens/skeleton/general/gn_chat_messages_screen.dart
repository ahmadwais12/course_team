import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnChatMessagesScreen extends ConsumerWidget {
  const GnChatMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Chat Messages',
      description: 'View chat message history',
      category: 'Communication',
      icon: Icons.chat,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'chat_messages',
    );
  }
}
