import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class GnPointHistoryScreen extends ConsumerWidget {
  const GnPointHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Point History',
      description: 'View gamification point history',
      category: 'Gamification',
      icon: Icons.emoji_events,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'point_history',
    );
  }
}
