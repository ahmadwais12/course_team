import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdEventsScreen extends ConsumerWidget {
  const AdEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Events',
      description: 'Manage school events',
      category: 'Events',
      icon: Icons.event,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'events',
    );
  }
}
