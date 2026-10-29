import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class AdFeeInstallmentsScreen extends ConsumerWidget {
  const AdFeeInstallmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Fee Installments',
      description: 'Manage fee installment plans',
      category: 'Financial',
      icon: Icons.calendar_today,
      accentColor: const Color(0xFF0EA5E9),
      tableName: 'fee_installments',
    );
  }
}
