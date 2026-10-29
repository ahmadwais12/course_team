import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdReceiptsScreen extends ConsumerWidget {
  const AdReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Receipts',
      description: 'View payment receipts',
      category: 'Financial',
      icon: Icons.receipt_long,
      accentColor: const Color(0xFF8B5CF6),
      tableName: 'receipts',
    );
  }
}
