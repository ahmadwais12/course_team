import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdReceptionEventsScreen extends ConsumerWidget {
  const AdReceptionEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Reception Events',
      description: 'Manage reception events',
      category: 'Events',
      icon: Icons.storefront,
      accentColor: const Color(0xFF3B82F6),
      tableName: 'reception_events',
    );
  }
}
