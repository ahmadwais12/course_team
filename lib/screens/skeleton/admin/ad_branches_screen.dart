import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdBranchesScreen extends ConsumerWidget {
  const AdBranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Branches',
      description: 'Manage organization branches',
      category: 'Organization',
      icon: Icons.account_balance,
      accentColor: const Color(0xFF6B7280),
      tableName: 'branches',
    );
  }
}
