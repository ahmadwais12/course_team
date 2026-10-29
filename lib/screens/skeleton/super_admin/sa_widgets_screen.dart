import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class SaWidgetsScreen extends ConsumerWidget {
  const SaWidgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Dashboard Widgets',
      description: 'Manage dashboard widgets',
      category: 'System',
      icon: Icons.widgets,
      accentColor: const Color(0xFF10B981),
      tableName: 'widgets',
    );
  }
}
