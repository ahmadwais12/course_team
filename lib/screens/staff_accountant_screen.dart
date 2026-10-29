import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class StaffAccountantScreen extends ConsumerStatefulWidget {
  const StaffAccountantScreen({super.key});
  @override
  ConsumerState<StaffAccountantScreen> createState() =>
      _StaffAccountantScreenState();
}

class _StaffAccountantScreenState extends ConsumerState<StaffAccountantScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _pendingInvoices = 0;
  double _totalRevenue = 0;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final invoices = await _sb.from('invoices').select();
      final payments = await _sb.from('payments').select('amount');
      final pending =
          await _sb.from('invoices').select('id').eq('status', 'pending');
      setState(() {
        _invoices = List<Map<String, dynamic>>.from(invoices);
        _pendingInvoices = pending.length;
        _totalRevenue = payments.fold<double>(
            0, (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble());
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? invoice}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _InvoiceFormPage(invoice: invoice),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadData();
  }

  void _confirmDelete(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_invoice, ref)),
        content: Text(
            'Delete invoice for student ${invoice['student_id']} (PKR ${invoice['amount']})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await _sb.from('invoices').delete().eq('id', invoice['id']);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            tt(LAll.all_error_x, ref, [e.toString()]))),
                  );
                }
              }
            },
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Widget _invoiceCard(Map<String, dynamic> invoice) {
    final status = (invoice['status'] ?? 'pending') as String;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Student: ${invoice['student_id']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const VSpace(AppSpacing.sm),
            Text(
              'PKR ${invoice['amount']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const VSpace(AppSpacing.xs),
            Text(
              'Due: ${invoice['due_date'] ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const VSpace(AppSpacing.sm),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showAddEditDialog(invoice: invoice),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red,
                  onPressed: () => _confirmDelete(invoice),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          const SectionHeader(
            title: 'Accountant',
            subtitle: 'Billing, invoices, and reconciliation',
            icon: Icons.calculate_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: 'Pending Invoices',
            value: '$_pendingInvoices',
            icon: Icons.receipt_long_outlined,
          ),
          const VSpace(AppSpacing.md),
          StatCard(
            title: 'Total Revenue',
            value: 'PKR ${_totalRevenue.toStringAsFixed(0)}',
            icon: Icons.account_balance_rounded,
          ),
          const VSpace(AppSpacing.lg),
          const Text(
            'Invoices',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const VSpace(AppSpacing.sm),
          if (_invoices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(t(LPay2.noInvoices, ref))),
            )
          else
            ..._invoices.map(_invoiceCard),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _InvoiceFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? invoice;
  const _InvoiceFormPage({this.invoice});

  @override
  ConsumerState<_InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<_InvoiceFormPage> {
  final _sb = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dueDateCtrl;
  late String _status;

  bool get _isEditing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    _studentIdCtrl = TextEditingController(text: widget.invoice?['student_id'] ?? '');
    _amountCtrl = TextEditingController(text: (widget.invoice?['amount'] ?? '').toString());
    _status = widget.invoice?['status'] ?? 'pending';
    _dueDateCtrl = TextEditingController(text: widget.invoice?['due_date'] ?? '');
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _amountCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = {
      'student_id': _studentIdCtrl.text.trim(),
      'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0,
      'status': _status,
      'due_date': _dueDateCtrl.text.trim(),
    };
    try {
      if (_isEditing) {
        await _sb.from('invoices').update(data).eq('id', widget.invoice!['id']);
      } else {
        await _sb.from('invoices').insert(data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'New Invoice'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () { debugPrint('[staff_accountant_screen] Save button CLICKED'); _save(); },
            child: Text(_isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _studentIdCtrl,
                decoration: const InputDecoration(labelText: 'Student ID'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const VSpace(AppSpacing.sm),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const VSpace(AppSpacing.sm),
              DropdownButtonFormField<String>(
initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  DropdownMenuItem(value: 'pending', child: Text(t(LPayment.cPending, ref))),
                  DropdownMenuItem(value: 'paid', child: Text(t(LPayment.paid, ref))),
                  DropdownMenuItem(value: 'overdue', child: Text(t(LAll.all_overdue, ref))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const VSpace(AppSpacing.sm),
              TextFormField(
                controller: _dueDateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Due Date (YYYY-MM-DD)',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
