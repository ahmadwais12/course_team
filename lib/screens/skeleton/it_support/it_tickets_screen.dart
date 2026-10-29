import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ItTicketsScreen extends ConsumerWidget {
  const ItTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'IT Tickets',
      description: 'Manage internal IT tickets',
      category: 'IT Support',
      icon: Icons.confirmation_number,
      accentColor: const Color(0xFF6366F1),
      tableName: 'it_tickets',
    );
  }
}
