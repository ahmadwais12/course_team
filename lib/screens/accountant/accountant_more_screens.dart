import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';
import 'package:course_emis/screens/accountant/finance_live_screens.dart';
import 'package:course_emis/screens/finance/expenses_tracking_screen.dart';
import 'package:course_emis/screens/finance/salary_management_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const ExpensesTrackingScreen();
}

class SalariesScreen extends ConsumerWidget {
  const SalariesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const SalaryManagementScreen();
}

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const BudgetsScreen();
}

class TaxationScreen extends ConsumerWidget {
  const TaxationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const TaxationRecordsScreen();
}

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      const PaymentHistoryLiveScreen();
}

class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const AdaptiveDataPage(
        title: 'Receipts',
        tableName: 'receipts',
        icon: Icons.receipt_long,
        accentColor: Color(0xFF6366F1),
        displayFields: [
          'receipt_no',
          'amount',
          'receipt_date',
          'payment_method',
          'description',
        ],
      );
}
