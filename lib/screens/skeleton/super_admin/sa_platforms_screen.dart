import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaPlatformsScreen extends ConsumerWidget {
  const SaPlatformsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Platforms',
      description: 'Manage EMIS platforms',
      category: 'Platform Management',
      icon: Icons.cloud,
      accentColor: const Color(0xFF6366F1),
      tableName: 'platforms',
    );
  }
}
