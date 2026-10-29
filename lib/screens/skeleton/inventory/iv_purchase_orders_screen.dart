import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class IvPurchaseOrdersScreen extends ConsumerWidget {
  const IvPurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Purchase Orders',
      description: 'Manage purchase orders and procurement',
      category: 'Inventory',
      icon: Icons.add_shopping_cart,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'purchase_orders',
    );
  }
}
