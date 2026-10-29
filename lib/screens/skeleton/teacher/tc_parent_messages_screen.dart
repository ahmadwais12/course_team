import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TcParentMessagesScreen extends ConsumerWidget {
  const TcParentMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Parent Messages',
      description: 'Communicate with parents',
      category: 'Communication',
      icon: Icons.message,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'parent_messages',
    );
  }
}
