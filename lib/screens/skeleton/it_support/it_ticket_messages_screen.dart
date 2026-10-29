import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class ItTicketMessagesScreen extends ConsumerWidget {
  const ItTicketMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Ticket Messages',
      description: 'View ticket conversation history',
      category: 'IT Support',
      icon: Icons.chat,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'it_ticket_messages',
    );
  }
}
