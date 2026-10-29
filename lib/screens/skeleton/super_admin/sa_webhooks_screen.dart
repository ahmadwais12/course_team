import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaWebhooksScreen extends ConsumerWidget {
  const SaWebhooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Webhooks',
      description: 'Manage webhook configurations',
      category: 'Integration',
      icon: Icons.webhook,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'webhooks',
    );
  }
}
