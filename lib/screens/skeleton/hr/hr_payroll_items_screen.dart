import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/skeleton_screen.dart';

class HrPayrollItemsScreen extends ConsumerWidget {
  const HrPayrollItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SkeletonScreen(
      title: 'Payroll Items',
      description: 'Manage payroll line items',
      category: 'Payroll',
      icon: Icons.receipt,
      accentColor: const Color(0xFF059669),
      tableName: 'payroll_items',
    );
  }
}
