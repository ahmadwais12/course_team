import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdInstallmentPlansScreen extends ConsumerWidget {
  const AdInstallmentPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Installment Plans',
      description: 'Define installment plan templates',
      category: 'Financial',
      icon: Icons.calendar_view_month,
      accentColor: const Color(0xFF6366F1),
      tableName: 'installment_plans',
    );
  }
}
