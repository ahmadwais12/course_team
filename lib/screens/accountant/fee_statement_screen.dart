import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/models/fee_models.dart';
import 'package:course_emis/repositories/fee_repository.dart';
import 'package:course_emis/utils/money_format.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

const _paymentMethods = [
  ('cash', 'Cash'),
  ('card', 'Card'),
  ('bank_transfer', 'Bank Transfer'),
  ('online', 'Online'),
  ('check', 'Check'),
  ('mobile_payment', 'Mobile Payment'),
];

/// Fee Statement — per-student assignments, installments, payments and
/// waivers. Recording a payment posts a balanced journal automatically.
class FeeStatementScreen extends ConsumerStatefulWidget {
  const FeeStatementScreen({super.key});

  @override
  ConsumerState<FeeStatementScreen> createState() =>
      _FeeStatementScreenState();
}

class _FeeStatementScreenState extends ConsumerState<FeeStatementScreen> {
  final _repo = FeeRepository();

  List<Map<String, dynamic>> _students = [];
  List<StudentFeeAssignment> _assignments = [];
  final Map<String, List<FeeInstallment>> _installments = {};
  final Map<String, bool> _expanded = {};

  bool _loadingStudents = true;
  bool _loadingStatement = false;
  String? _studentId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _repo.listStudents();
      if (!mounted) return;
      setState(() {
        _students = students;
        _loadingStudents = false;
      });
      if (students.isNotEmpty) _selectStudent(students.first['id'] as String);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStudents = false;
        _error = 'Failed to load students: $e';
      });
    }
  }

  Future<void> _selectStudent(String id) async {
    setState(() {
      _studentId = id;
      _loadingStatement = true;
      _assignments = [];
      _installments.clear();
      _expanded.clear();
    });
    try {
      final assignments = await _repo.listAssignments(studentId: id);
      if (!mounted) return;
      setState(() => _assignments = assignments);
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to load statement: $e');
    } finally {
      if (mounted) setState(() => _loadingStatement = false);
    }
  }

  Future<List<FeeInstallment>> _installmentsFor(StudentFeeAssignment a) async {
    final cached = _installments[a.id];
    if (cached != null) return cached;
    final data = await _repo.listInstallments(assignmentId: a.id);
    _installments[a.id] = data;
    return data;
  }

  Future<void> _recordPayment(StudentFeeAssignment a) async {
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (_) => _PaymentDialog(assignment: a),
    );
    if (result == null) return;

    final (amount, method) = result;
    try {
      final payment = await _repo.recordAssignmentPayment(
        assignmentId: a.id,
        amount: amount,
        paymentMethod: method,
      );
      if (!mounted) return;
      _snack('Payment recorded'
          '${payment.journalId != null ? ' and journal posted' : ''}.');
      _selectStudent(_studentId!);
    } catch (e) {
      if (!mounted) return;
      _snack('Payment failed: $e');
    }
  }

  Future<void> _waive(StudentFeeAssignment a) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Waive Fee'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Waive'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final reason = reasonCtrl.text.trim();
    if (reason.isEmpty) {
      _snack('A waiver reason is required.');
      return;
    }
    try {
      await _repo.waiveAssignment(assignmentId: a.id, reason: reason);
      if (!mounted) return;
      _snack('Fee waived.');
      _selectStudent(_studentId!);
    } catch (e) {
      if (!mounted) return;
      _snack('Waive failed: $e');
    }
  }

  Future<void> _createInvoice() async {
    final outstanding =
        _assignments.where((a) => a.outstandingAmount > 0).toList();
    if (outstanding.isEmpty) {
      _snack('No outstanding fees to invoice.');
      return;
    }
    try {
      final invoice = await _repo.createInvoiceFromAssignments(
        studentId: _studentId!,
        assignments: outstanding,
      );
      if (!mounted) return;
      _snack('Invoice ${invoice['invoice_number'] ?? ''} created.');
    } catch (e) {
      if (!mounted) return;
      _snack('Invoice creation failed: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final totalAssigned = _assignments.fold<double>(0, (s, a) => s + a.amount);
    final totalPaid = _assignments.fold<double>(0, (s, a) => s + a.paidAmount);
    final totalOutstanding =
        _assignments.fold<double>(0, (s, a) => s + a.outstandingAmount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Student Fee Statement'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/fee-assignments'),
            icon: const Icon(Icons.add),
            label: const Text('Assign'),
          ),
        ],
      ),
      body: _buildBody(theme, totalAssigned, totalPaid, totalOutstanding),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    double totalAssigned,
    double totalPaid,
    double totalOutstanding,
  ) {
    if (_error != null && _students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _loadStudents, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_loadingStudents)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _studentId,
            decoration: const InputDecoration(
                labelText: 'Student', border: OutlineInputBorder()),
            items: _students
                .map((s) => DropdownMenuItem(
                      value: s['id'] as String,
                      child: Text('${s['full_name'] ?? 'Unknown'}'
                          '${(s['student_code'] as String?) != null ? ' (${s['student_code']})' : ''}'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) _selectStudent(v);
            },
          ),
        const SizedBox(height: 16),

        if (_loadingStatement)
          const ListSkeleton(itemCount: 3)
        else ...[
          // Summary row
          Row(
            children: [
              _stat(theme, 'Assigned', totalAssigned, Colors.blue),
              const SizedBox(width: 8),
              _stat(theme, 'Paid', totalPaid, Colors.green),
              const SizedBox(width: 8),
              _stat(theme, 'Outstanding', totalOutstanding, Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          if (_assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text('No fee assignments for this student yet.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: Colors.grey)),
              ),
            )
          else
            ..._assignments.map((a) => _assignmentCard(theme, a)),

          if (_assignments.any((a) => a.outstandingAmount > 0)) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _createInvoice,
              icon: const Icon(Icons.request_quote_outlined),
              label: Text(
                  'Create invoice for ${_assignments.where((a) => a.outstandingAmount > 0).length} outstanding fee(s)'),
            ),
          ],
        ],
      ],
    );
  }

  Widget _stat(ThemeData theme, String label, double value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(fmtAmount(value),
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 15)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _assignmentCard(ThemeData theme, StudentFeeAssignment a) {
    final isOpen = a.status == 'pending' || a.status == 'partial' || a.status == 'overdue';
    final statusColor = _statusColor(a.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        initiallyExpanded: _expanded[a.id] ?? false,
        onExpansionChanged: (open) async {
          setState(() => _expanded[a.id] = open);
          if (open) await _installmentsFor(a);
          if (mounted) setState(() {});
        },
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.receipt_long_rounded, color: statusColor),
        ),
        title: Text(a.structureName ?? a.feeTypeName ?? 'Fee'),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Due ${_dateLabel(a.dueDate)}'
                  '${a.frequency != null ? ' • ${_freqLabel(a.frequency)}' : ''}'),
              const SizedBox(height: 2),
              Text(
                'Paid ${fmtMoney(a.paidAmount)} of ${fmtMoney(a.amount)}'
                ' — outstanding ${fmtMoney(a.outstandingAmount)}',
              ),
            ],
          ),
        ),
        trailing: Chip(
          label: Text(a.status.toUpperCase()),
          labelStyle: const TextStyle(fontSize: 10, color: Colors.white),
          backgroundColor: statusColor,
        ),
        children: [
          // Installments
          if (_installments[a.id]?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text('Installments',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  for (final inst in _installments[a.id]!)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        inst.status == 'paid'
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: inst.status == 'paid'
                            ? Colors.green
                            : Colors.grey,
                      ),
                      title: Text(
                          '#${inst.installmentNumber} • ${fmtMoney(inst.amount)}'),
                      subtitle: Text('Due ${_dateLabel(inst.dueDate)}'),
                      trailing: Text(inst.status.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              color: inst.status == 'paid'
                                  ? Colors.green
                                  : Colors.orange)),
                    ),
                ],
              ),
            ),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                if (isOpen) ...[
                  FilledButton.icon(
                    onPressed: () => _recordPayment(a),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Record Payment'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _waive(a),
                    icon: const Icon(Icons.volunteer_activism_outlined, size: 18),
                    label: const Text('Waive'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'waived':
        return Colors.grey;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _freqLabel(String? f) {
    switch (f) {
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'One Time';
    }
  }
}

class _PaymentDialog extends StatefulWidget {
  final StudentFeeAssignment assignment;
  const _PaymentDialog({required this.assignment});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountCtrl = TextEditingController();
  String _method = 'cash';

  @override
  void initState() {
    super.initState();
    _amountCtrl.text =
        widget.assignment.outstandingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    Navigator.pop(context, (amount, _method));
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    return AlertDialog(
      title: const Text('Record Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${a.structureName ?? 'Fee'} — outstanding '
                '${fmtMoney(a.outstandingAmount)}'),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (AFN)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(_method),
              initialValue: _method,
              decoration: const InputDecoration(
                  labelText: 'Payment method', border: OutlineInputBorder()),
              items: _paymentMethods
                  .map((m) =>
                      DropdownMenuItem(value: m.$1, child: Text(m.$2)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _method = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: _submit,
          child: const Text('Record & Post Journal'),
        ),
      ],
    );
  }
}
