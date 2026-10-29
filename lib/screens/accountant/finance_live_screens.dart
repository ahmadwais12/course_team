import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/adaptive/adaptive_data_page.dart';
import 'package:course_emis/widgets/adaptive/adaptive_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Finance dashboard with live counts from ledger tables.
class FinanceDashboardScreen extends ConsumerStatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  ConsumerState<FinanceDashboardScreen> createState() =>
      _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState
    extends ConsumerState<FinanceDashboardScreen> {
  bool _loading = true;
  Map<String, num> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final sb = Supabase.instance.client;
    try {
      final payments = await sb
          .from('payments')
          .select('amount')
          .eq('status', 'completed');
      final expenses =
          await sb.from('expenses').select('amount').eq('status', 'paid');
      final invoices =
          await sb.from('invoices').select('id').eq('status', 'pending');
      final journals =
          await sb.from('journals').select('id').eq('is_posted', true);
      final petty = await sb.from('petty_cash_funds').select('current_balance');

      double sum(List raw, String key) => raw.fold<double>(
            0,
            (a, e) => a + (((e as Map)[key] as num?)?.toDouble() ?? 0),
          );

      if (!mounted) return;
      setState(() {
        _stats = {
          'payments': sum(List.from(payments), 'amount'),
          'expenses': sum(List.from(expenses), 'amount'),
          'pending_invoices': (invoices as List).length,
          'posted_journals': (journals as List).length,
          'petty_cash': sum(List.from(petty), 'current_balance'),
        };
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Finance Dashboard',
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
      ],
      body: _loading
          ? const Center(child: AdaptiveProgress())
          : AdaptiveRefresh(
              onRefresh: _load,
              child: ListView(
                physics: PlatformAdaptive.scrollPhysics(
                  const AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                children: [
                  _StatCard(
                    title: 'Completed Payments',
                    value: _stats['payments']?.toStringAsFixed(2) ?? '0',
                    icon: Icons.payments_rounded,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'Paid Expenses',
                    value: _stats['expenses']?.toStringAsFixed(2) ?? '0',
                    icon: Icons.receipt_long,
                    color: Colors.red,
                  ),
                  _StatCard(
                    title: 'Pending Invoices',
                    value: '${_stats['pending_invoices'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Posted Journals',
                    value: '${_stats['posted_journals'] ?? 0}',
                    icon: Icons.menu_book,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Petty Cash Balance',
                    value: _stats['petty_cash']?.toStringAsFixed(2) ?? '0',
                    icon: Icons.account_balance_wallet,
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}

class JournalsScreen extends ConsumerWidget {
  const JournalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveDataPage(
      title: 'Journals',
      tableName: 'journals',
      icon: Icons.menu_book_rounded,
      accentColor: const Color(0xFF10B981),
      subtitle: 'Double-entry journal headers',
      displayFields: const [
        'journal_no',
        'description',
        'journal_date',
        'total_debit',
        'total_credit',
        'is_posted',
      ],
      defaultInsert: () => {
        'journal_date': DateTime.now().toIso8601String().substring(0, 10),
        'description': 'Manual journal',
        'is_posted': false,
        'total_debit': 0,
        'total_credit': 0,
      },
    );
  }
}

class JournalEntriesScreen extends ConsumerWidget {
  const JournalEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdaptiveDataPage(
      title: 'Journal Entries',
      tableName: 'journal_entries',
      icon: Icons.list_alt_rounded,
      accentColor: Color(0xFF059669),
      displayFields: [
        'account_code',
        'description',
        'debit',
        'credit',
      ],
    );
  }
}

class PettyCashFundsScreen extends ConsumerWidget {
  const PettyCashFundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveDataPage(
      title: 'Petty Cash Funds',
      tableName: 'petty_cash_funds',
      icon: Icons.account_balance_wallet_outlined,
      accentColor: const Color(0xFF0D9488),
      displayFields: const [
        'name',
        'current_balance',
        'initial_balance',
        'currency',
        'is_active',
      ],
      defaultInsert: () => {
        'name': 'Main Petty Cash',
        'initial_balance': 0,
        'current_balance': 0,
        'currency': 'AFN',
        'is_active': true,
      },
    );
  }
}

class PettyCashEntriesScreen extends ConsumerWidget {
  const PettyCashEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdaptiveDataPage(
      title: 'Petty Cash Entries',
      tableName: 'petty_cash_entries',
      icon: Icons.receipt_outlined,
      accentColor: Color(0xFF14B8A6),
      displayFields: [
        'entry_type',
        'amount',
        'expense_category',
        'status',
      ],
    );
  }
}

class AccountsLedgerScreen extends ConsumerWidget {
  const AccountsLedgerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveDataPage(
      title: 'Chart of Accounts',
      tableName: 'accounts',
      icon: Icons.account_tree_outlined,
      accentColor: const Color(0xFF2563EB),
      displayFields: const [
        'name',
        'account_code',
        'account_type',
        'normal_balance',
        'is_active',
      ],
      defaultInsert: () => {
        'name': 'New Account',
        'account_type': 'expense',
        'normal_balance': 'debit',
        'is_active': true,
        'status': 'active',
      },
    );
  }
}

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveDataPage(
      title: 'Budgets',
      tableName: 'budgets',
      icon: Icons.pie_chart_outline,
      accentColor: Colors.teal,
      displayFields: const [
        'category',
        'fiscal_year',
        'allocated_amount',
        'spent_amount',
      ],
      defaultInsert: () => {
        'fiscal_year': DateTime.now().year.toString(),
        'category': 'General',
        'allocated_amount': 0,
        'spent_amount': 0,
      },
    );
  }
}

class PaymentHistoryLiveScreen extends ConsumerWidget {
  const PaymentHistoryLiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdaptiveDataPage(
      title: 'Payment History',
      tableName: 'payments',
      icon: Icons.history,
      accentColor: Color(0xFF7C3AED),
      displayFields: [
        'payment_number',
        'amount',
        'payment_method',
        'payment_date',
        'status',
      ],
    );
  }
}

class TaxationRecordsScreen extends ConsumerWidget {
  const TaxationRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptiveDataPage(
      title: 'Taxation',
      tableName: 'expenses',
      icon: Icons.gavel_rounded,
      accentColor: Colors.brown,
      subtitle: 'Tax-related expense records',
      displayFields: const [
        'category',
        'amount',
        'expense_date',
        'status',
        'description',
      ],
      defaultInsert: () => {
        'category': 'tax',
        'amount': 0,
        'expense_date': DateTime.now().toIso8601String().substring(0, 10),
        'status': 'pending',
        'description': 'Tax entry',
      },
    );
  }
}
