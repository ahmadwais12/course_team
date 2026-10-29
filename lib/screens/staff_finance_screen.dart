import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffFinanceScreen extends ConsumerStatefulWidget {
  const StaffFinanceScreen({super.key});
  @override
  ConsumerState<StaffFinanceScreen> createState() =>
      _StaffFinanceScreenState();
}

class _StaffFinanceScreenState extends ConsumerState<StaffFinanceScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _pendingPayrolls = 0;
  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final payrolls = await _sb.from('invoices').select('id').eq('status', 'pending');
      final payments = await _sb
          .from('payments')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      setState(() {
        _pendingPayrolls = payrolls.length;
        _payments = List<Map<String, dynamic>>.from(payments);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        const SectionHeader(
          title: 'Finance',
          subtitle: 'Payroll, expenses, procurement',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const VSpace(AppSpacing.lg),
        StatCard(
          title: 'Pending Payrolls',
          value: '$_pendingPayrolls',
          icon: Icons.payments_outlined,
        ),
        const VSpace(AppSpacing.md),
        AppTable<Map<String, dynamic>>(
          columns: const ['Description', 'Type', 'Amount'],
          rows: _payments,
          rowBuilder: (context, row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(row['description']?.toString() ?? '-'),
                  ),
                  SizedBox(
                    width: 160,
                    child: Text(row['payment_type']?.toString() ?? '-'),
                  ),
                  SizedBox(
                    width: 160,
                    child: Text('PKR ${row['amount']?.toString() ?? '0'}'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
