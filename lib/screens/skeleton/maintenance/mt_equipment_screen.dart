import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class MtEquipmentScreen extends ConsumerWidget {
  const MtEquipmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Equipment',
      description: 'Track equipment condition and status',
      category: 'Maintenance',
      icon: Icons.engineering,
      accentColor: const Color(0xFFF59E0B),
      tableName: 'assets',
    );
  }
}
