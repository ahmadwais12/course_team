import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdViewCountersScreen extends ConsumerWidget {
  const AdViewCountersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'View Counters',
      description: 'Track page view statistics',
      category: 'Analytics',
      icon: Icons.visibility,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'view_counters',
    );
  }
}
