import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaAppUpdatesScreen extends ConsumerWidget {
  const SaAppUpdatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'App Updates',
      description: 'Manage application updates',
      category: 'System',
      icon: Icons.system_update,
      accentColor: const Color(0xFF2563EB),
      tableName: 'app_updates',
    );
  }
}
