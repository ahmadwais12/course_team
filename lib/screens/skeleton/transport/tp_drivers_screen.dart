import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class TpDriversScreen extends ConsumerWidget {
  const TpDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'All Drivers',
      description: 'Manage transport drivers',
      category: 'Transport',
      icon: Icons.person,
      accentColor: const Color(0xFFF97316),
      tableName: 'drivers',
    );
  }
}
