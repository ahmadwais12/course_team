import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class LbBookSalesScreen extends ConsumerWidget {
  const LbBookSalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Book Sales',
      description: 'Track book sales',
      category: 'Library',
      icon: Icons.shopping_cart,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'book_sales',
    );
  }
}
