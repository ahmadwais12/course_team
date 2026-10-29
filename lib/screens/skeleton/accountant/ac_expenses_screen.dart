import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';

class AcExpensesScreen extends ConsumerWidget {
  const AcExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdaptiveDataPage(
        title: 'Expenses',
        tableName: 'expenses',
        icon: Icons.receipt_long,
        accentColor: Colors.red,
        displayFields: [
          'category',
          'amount',
          'expense_date',
          'status',
          'vendor',
        ],
      );
}
