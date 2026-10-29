import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaCrossTenantAnalyticsScreen extends ConsumerWidget {
  const SaCrossTenantAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Cross-Tenant Analytics',
      description: 'Analytics across all tenants',
      category: 'Analytics',
      icon: Icons.analytics,
      accentColor: const Color(0xFF06B6D4),
      tableName: 'cross_tenant_analytics',
    );
  }
}
