import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaRolesScreen extends ConsumerWidget {
  const SaRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Roles',
      description: 'Manage system roles and permissions',
      category: 'Platform Management',
      icon: Icons.admin_panel_settings,
      accentColor: const Color(0xFF7C3AED),
      tableName: 'roles',
    );
  }
}
