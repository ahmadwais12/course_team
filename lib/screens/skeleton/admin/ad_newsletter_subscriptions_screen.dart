import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdNewsletterSubscriptionsScreen extends ConsumerWidget {
  const AdNewsletterSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Newsletter Subscriptions',
      description: 'Manage email newsletter subscriptions',
      category: 'Communication',
      icon: Icons.email_outlined,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'newsletter_subscriptions',
    );
  }
}
