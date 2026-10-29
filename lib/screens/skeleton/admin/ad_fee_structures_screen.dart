import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdFeeStructuresScreen extends ConsumerWidget {
  const AdFeeStructuresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Fee Structures',
      description: 'Manage fee structures',
      category: 'Financial',
      icon: Icons.account_balance,
      accentColor: const Color(0xFF059669),
      tableName: 'fee_structures',
    );
  }
}
