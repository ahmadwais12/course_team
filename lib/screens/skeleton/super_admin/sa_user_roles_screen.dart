import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaUserRolesScreen extends ConsumerWidget {
  const SaUserRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'User Roles',
      description: 'Manage user role assignments',
      category: 'User Management',
      icon: Icons.person_pin,
      accentColor: const Color(0xFF5B21B6),
      tableName: 'user_roles',
    );
  }
}
