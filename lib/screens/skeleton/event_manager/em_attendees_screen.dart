import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class EmAttendeesScreen extends ConsumerWidget {
  const EmAttendeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Attendees',
      description: 'Manage event registrations and attendees',
      category: 'Events',
      icon: Icons.group_add,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'event_registrations',
    );
  }
}
