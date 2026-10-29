import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class IvStockReconciliationScreen extends ConsumerWidget {
  const IvStockReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Stock Reconciliation',
      description: 'Reconcile inventory stock levels',
      category: 'Inventory',
      icon: Icons.fact_check,
      accentColor: const Color(0xFF059669),
      tableName: 'stock_reconciliation',
    );
  }
}
