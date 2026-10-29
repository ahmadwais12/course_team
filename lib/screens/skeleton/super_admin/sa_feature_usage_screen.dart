import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaFeatureUsageScreen extends ConsumerWidget {
  const SaFeatureUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Feature Usage',
      description: 'Track feature usage statistics',
      category: 'Analytics',
      icon: Icons.trending_up,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'feature_usage_logs',
    );
  }
}
