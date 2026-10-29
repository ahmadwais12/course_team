import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdHomeStatsScreen extends ConsumerWidget {
  const AdHomeStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Home Stats',
      description: 'Manage homepage statistics display',
      category: 'Website',
      icon: Icons.bar_chart,
      accentColor: const Color(0xFF10B981),
      tableName: 'home_stats',
    );
  }
}
