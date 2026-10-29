import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaRolePermissionsScreen extends ConsumerWidget {
  const SaRolePermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Role Permissions',
      description: 'Assign permissions to roles',
      category: 'Platform Management',
      icon: Icons.security,
      accentColor: const Color(0xFF6D28D9),
      tableName: 'role_permissions',
    );
  }
}
