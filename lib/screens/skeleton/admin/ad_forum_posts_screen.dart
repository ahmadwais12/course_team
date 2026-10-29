import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdForumPostsScreen extends ConsumerWidget {
  const AdForumPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Forum Posts',
      description: 'Manage discussion forum posts',
      category: 'Communication',
      icon: Icons.forum,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'forum_posts',
    );
  }
}
