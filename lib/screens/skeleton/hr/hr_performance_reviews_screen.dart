import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrPerformanceReviewsScreen extends ConsumerWidget {
  const HrPerformanceReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Performance Reviews',
      description: 'Manage employee performance reviews',
      category: 'HR',
      icon: Icons.trending_up,
      accentColor: const Color(0xFF10B981),
      tableName: 'performance_reviews',
    );
  }
}
