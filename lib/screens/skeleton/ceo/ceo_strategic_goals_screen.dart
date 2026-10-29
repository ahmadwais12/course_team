import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class CeoStrategicGoalsScreen extends ConsumerWidget {
  const CeoStrategicGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Strategic Goals',
      description: 'Manage strategic goals and KPIs',
      category: 'Executive',
      icon: Icons.track_changes,
      accentColor: const Color(0xFF10B981),
      tableName: 'strategic_goals',
    );
  }
}
