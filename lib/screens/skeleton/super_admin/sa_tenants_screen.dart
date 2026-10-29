import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaTenantsScreen extends ConsumerWidget {
  const SaTenantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'All Tenants',
      description: 'Manage all tenants',
      category: 'Platform Management',
      icon: Icons.business,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'tenants',
    );
  }
}
