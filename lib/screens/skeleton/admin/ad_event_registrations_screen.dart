import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdEventRegistrationsScreen extends ConsumerWidget {
  const AdEventRegistrationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Event Registrations',
      description: 'Manage event registrations',
      category: 'Events',
      icon: Icons.event_available,
      accentColor: const Color(0xFF6D28D9),
      tableName: 'event_registrations',
    );
  }
}
