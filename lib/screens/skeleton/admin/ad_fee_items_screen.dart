import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdFeeItemsScreen extends ConsumerWidget {
  const AdFeeItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Fee Items',
      description: 'Manage individual fee items',
      category: 'Financial',
      icon: Icons.receipt,
      accentColor: const Color(0xFF10B981),
      tableName: 'fee_items',
    );
  }
}
