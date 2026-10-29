import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaApiUsageScreen extends ConsumerWidget {
  const SaApiUsageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'API Usage Logs',
      description: 'View API usage analytics',
      category: 'Monitoring',
      icon: Icons.bar_chart,
      accentColor: const Color(0xFFF43F5E),
      tableName: 'api_usage_logs',
    );
  }
}
