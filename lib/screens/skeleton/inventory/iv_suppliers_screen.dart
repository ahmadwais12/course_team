import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class IvSuppliersScreen extends ConsumerWidget {
  const IvSuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Suppliers',
      description: 'Manage suppliers and vendors',
      category: 'Inventory',
      icon: Icons.business_center,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'suppliers',
    );
  }
}
