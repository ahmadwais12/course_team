import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ItSupportTicketsScreen extends ConsumerWidget {
  const ItSupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Support Tickets',
      description: 'Manage IT support tickets',
      category: 'IT Support',
      icon: Icons.support_agent,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'support_tickets',
    );
  }
}
