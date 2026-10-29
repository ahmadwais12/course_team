import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class IvAssetAssignmentsScreen extends ConsumerWidget {
  const IvAssetAssignmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Asset Assignments',
      description: 'Track asset assignments to staff/students',
      category: 'Assets',
      icon: Icons.qr_code,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'asset_assignments',
    );
  }
}
