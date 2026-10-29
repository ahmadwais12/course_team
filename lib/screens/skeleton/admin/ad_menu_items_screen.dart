import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdMenuItemsScreen extends ConsumerWidget {
  const AdMenuItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Menu Items',
      description: 'Manage website navigation menu',
      category: 'Website',
      icon: Icons.menu,
      accentColor: const Color(0xFF6B7280),
      tableName: 'menu_items',
    );
  }
}
