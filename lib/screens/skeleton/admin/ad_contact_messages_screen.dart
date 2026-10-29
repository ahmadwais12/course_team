import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdContactMessagesScreen extends ConsumerWidget {
  const AdContactMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Contact Messages',
      description: 'View contact form submissions',
      category: 'Communication',
      icon: Icons.message_outlined,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'contact_messages',
    );
  }
}
