import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaProfilesScreen extends ConsumerWidget {
  const SaProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'All Profiles',
      description: 'Manage all user profiles across tenants',
      category: 'User Management',
      icon: Icons.people,
      accentColor: const Color(0xFFA855F7),
      tableName: 'users',
    );
  }
}
