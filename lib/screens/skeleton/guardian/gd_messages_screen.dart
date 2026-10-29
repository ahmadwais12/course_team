import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GdMessagesScreen extends ConsumerWidget {
  const GdMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Messages',
      description: 'View messages from school',
      category: 'Communication',
      icon: Icons.message,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'parent_messages',
    );
  }
}
