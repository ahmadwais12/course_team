import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class IvInventoryItemsScreen extends ConsumerWidget {
  const IvInventoryItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Inventory Items',
      description: 'Manage all inventory items',
      category: 'Inventory',
      icon: Icons.inventory_2,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'inventory_items',
    );
  }
}
