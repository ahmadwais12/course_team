import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdViewTrendsScreen extends ConsumerWidget {
  const AdViewTrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'View Trends',
      description: 'Analyze view trends over time',
      category: 'Analytics',
      icon: Icons.trending_up,
      accentColor: const Color(0xFF10B981),
      tableName: 'view_trends',
    );
  }
}
