import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class MtVendorsScreen extends ConsumerWidget {
  const MtVendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Vendors',
      description: 'Manage maintenance vendors',
      category: 'Maintenance',
      icon: Icons.local_shipping,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'suppliers',
    );
  }
}
