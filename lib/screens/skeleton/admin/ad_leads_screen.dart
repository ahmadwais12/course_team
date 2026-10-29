import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdLeadsScreen extends ConsumerWidget {
  const AdLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Leads',
      description: 'Manage sales and admission leads',
      category: 'Admissions',
      icon: Icons.leaderboard,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'leads',
    );
  }
}
