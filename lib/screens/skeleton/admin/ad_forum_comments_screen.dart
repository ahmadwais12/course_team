import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdForumCommentsScreen extends ConsumerWidget {
  const AdForumCommentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Forum Comments',
      description: 'Manage forum post comments',
      category: 'Communication',
      icon: Icons.comment,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'forum_comments',
    );
  }
}
