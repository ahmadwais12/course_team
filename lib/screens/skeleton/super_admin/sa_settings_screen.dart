import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaSettingsScreen extends ConsumerWidget {
  const SaSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'System Settings',
      description: 'Platform-wide system settings',
      category: 'System',
      icon: Icons.settings_applications,
      accentColor: const Color(0xFF6B7280),
      tableName: 'settings',
    );
  }
}
