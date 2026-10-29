import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class IvInventoryTransactionsScreen extends ConsumerWidget {
  const IvInventoryTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Inventory Transactions',
      description: 'Track inventory movement',
      category: 'Inventory',
      icon: Icons.swap_horiz,
      accentColor: const Color(0xFF10B981),
      tableName: 'inventory_transactions',
    );
  }
}
