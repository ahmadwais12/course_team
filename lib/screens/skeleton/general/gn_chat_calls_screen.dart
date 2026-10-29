import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnChatCallsScreen extends ConsumerWidget {
  const GnChatCallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Chat Calls',
      description: 'View chat call history',
      category: 'Communication',
      icon: Icons.call,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'chat_calls',
    );
  }
}
