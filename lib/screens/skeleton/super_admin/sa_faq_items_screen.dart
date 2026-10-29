import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaFaqItemsScreen extends ConsumerWidget {
  const SaFaqItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'FAQ Items',
      description: 'Manage platform FAQ items',
      category: 'Support',
      icon: Icons.help,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'faq_items',
    );
  }
}
