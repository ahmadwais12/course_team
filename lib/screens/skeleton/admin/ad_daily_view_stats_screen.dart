import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdDailyViewStatsScreen extends ConsumerWidget {
  const AdDailyViewStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Daily View Stats',
      description: 'Daily page view statistics',
      category: 'Analytics',
      icon: Icons.date_range,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'daily_view_stats',
    );
  }
}
