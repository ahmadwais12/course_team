import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class MtMaintenanceRequestsScreen extends ConsumerWidget {
  const MtMaintenanceRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Maintenance Requests',
      description: 'Manage maintenance service requests',
      category: 'Maintenance',
      icon: Icons.build,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'maintenance_requests',
    );
  }
}
