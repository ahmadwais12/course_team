import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdEventVenuesScreen extends ConsumerWidget {
  const AdEventVenuesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Event Venues',
      description: 'Manage event venues',
      category: 'Events',
      icon: Icons.place,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'event_venues',
    );
  }
}
