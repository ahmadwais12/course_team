import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class MtItemConditionHistoryScreen extends ConsumerWidget {
  const MtItemConditionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Item Condition History',
      description: 'Track equipment condition over time',
      category: 'Maintenance',
      icon: Icons.history,
      accentColor: const Color(0xFFE11D48),
      tableName: 'item_condition_history',
    );
  }
}
