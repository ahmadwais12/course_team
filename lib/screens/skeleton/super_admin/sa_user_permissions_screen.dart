import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaUserPermissionsScreen extends ConsumerWidget {
  const SaUserPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'User Permissions',
      description: 'Manage individual user permissions',
      category: 'User Management',
      icon: Icons.verified_user,
      accentColor: const Color(0xFF4C1D95),
      tableName: 'user_permissions',
    );
  }
}
