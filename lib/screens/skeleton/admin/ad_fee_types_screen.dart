import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdFeeTypesScreen extends ConsumerWidget {
  const AdFeeTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Fee Types',
      description: 'Manage fee type categories',
      category: 'Financial',
      icon: Icons.category,
      accentColor: const Color(0xFF14B8A6),
      tableName: 'fee_types',
    );
  }
}
