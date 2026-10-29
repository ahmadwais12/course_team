import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class LbBookPurchasesScreen extends ConsumerWidget {
  const LbBookPurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Book Purchases',
      description: 'Track book purchase orders',
      category: 'Library',
      icon: Icons.add_shopping_cart,
      accentColor: const Color(0xFF10B981),
      tableName: 'book_purchases',
    );
  }
}
