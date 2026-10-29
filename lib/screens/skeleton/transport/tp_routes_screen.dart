import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TpRoutesScreen extends ConsumerWidget {
  const TpRoutesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'All Routes',
      description: 'Manage transport routes',
      category: 'Transport',
      icon: Icons.route,
      accentColor: const Color(0xFFE11D48),
      tableName: 'routes',
    );
  }
}
