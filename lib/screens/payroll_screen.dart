import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/teacher.dart';
import 'package:course_emis/providers/payroll_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollsAsync = ref.watch(payrollNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPayrollDialog(context, ref),
        icon: const Icon(Icons.payments),
        label: const Text('Process Payroll'),
      ),
      body: Padding(
        padding: AppSpacing.paddingLg,
        child: payrollsAsync.when(
          data: (payrolls) => payrolls.isEmpty
              ? Center(
                  child: Text('No payroll records',
                      style: Theme.of(context).textTheme.bodyLarge))
              : ListView.separated(
                  itemCount: payrolls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final payroll = payrolls[index];
                    return _PayrollCard(
                      payroll: payroll,
                      onEdit: () => _showPayrollDialog(context, ref, payroll: payroll),
                      onDelete: () => _showDeleteConfirmation(context, ref, payroll),
                    );
                  },
                ),
          loading: () => const ListSkeleton(itemCount: 5),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Future<void> _showPayrollDialog(
    BuildContext context,
    WidgetRef ref, {
    Payroll? payroll,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _PayrollFormPage(payroll: payroll),
        fullscreenDialog: true,
      ),
    );
    if (result == true) ref.invalidate(payrollNotifierProvider);
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Payroll payroll,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payroll'),
        content: Text(
          'Are you sure you want to delete the payroll record for ${payroll.teacherId} (${payroll.period})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () {
              ref
                  .read(payrollNotifierProvider.notifier)
                  .deletePayroll(payroll.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PayrollFormPage extends ConsumerStatefulWidget {
  final Payroll? payroll;
  const _PayrollFormPage({this.payroll});

  @override
  ConsumerState<_PayrollFormPage> createState() => _PayrollFormPageState();
}

class _PayrollFormPageState extends ConsumerState<_PayrollFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _teacherIdCtl;
  late final TextEditingController _baseSalaryCtl;
  late final TextEditingController _periodCtl;

  bool get _isEditing => widget.payroll != null;

  @override
  void initState() {
    super.initState();
    _teacherIdCtl = TextEditingController(text: widget.payroll?.teacherId ?? '');
    _baseSalaryCtl = TextEditingController(text: widget.payroll != null ? widget.payroll!.baseSalary.toString() : '');
    _periodCtl = TextEditingController(text: widget.payroll?.period ?? '');
  }

  @override
  void dispose() {
    _teacherIdCtl.dispose();
    _baseSalaryCtl.dispose();
    _periodCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Payroll' : 'Process Payroll'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _teacherIdCtl,
              decoration: const InputDecoration(labelText: 'Teacher ID'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _baseSalaryCtl,
              decoration: const InputDecoration(
                labelText: 'Base Salary',
                prefixText: 'PKR ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _periodCtl,
              decoration: const InputDecoration(labelText: 'Period (e.g., Jan 2024)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () { debugPrint('[payroll_screen] Save button CLICKED'); _save(); },
              child: Text(_isEditing ? 'Update' : 'Process'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final ref = this.ref;
    final baseSalary = double.parse(_baseSalaryCtl.text);
    final notifier = ref.read(payrollNotifierProvider.notifier);
    if (_isEditing) {
      final updated = widget.payroll!.copyWith(
        teacherId: _teacherIdCtl.text,
        baseSalary: baseSalary,
        netSalary: baseSalary +
            widget.payroll!.bonuses.fold(0.0, (a, b) => a + b) -
            widget.payroll!.deductions.fold(0.0, (a, b) => a + b),
        period: _periodCtl.text,
      );
      notifier.updatePayroll(updated);
    } else {
      final now = DateTime.now();
      final newPayroll = Payroll(
        id: 'payroll_${now.millisecondsSinceEpoch}',
        teacherId: _teacherIdCtl.text,
        baseSalary: baseSalary,
        bonuses: [],
        deductions: [],
        netSalary: baseSalary,
        period: _periodCtl.text,
        status: PayrollStatus.pending,
        createdAt: now,
      );
      notifier.addPayroll(newPayroll);
    }
    Navigator.pop(context, true);
  }
}

class _PayrollCard extends StatelessWidget {
  final Payroll payroll;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PayrollCard({
    required this.payroll,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: payroll.status == PayrollStatus.paid
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                child: Icon(
                  payroll.status == PayrollStatus.paid
                      ? Icons.check
                      : Icons.pending,
                  color: payroll.status == PayrollStatus.paid
                      ? Colors.blue
                      : Colors.orange,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teacher: ${payroll.teacherId}',
                        style: theme.textTheme.titleMedium),
                    Text('${payroll.period} â€¢ ${payroll.status.name}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Text('PKR ${payroll.netSalary.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: Colors.blue)),
            ],
          ),
          if (payroll.bonuses.isNotEmpty || payroll.deductions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (payroll.bonuses.isNotEmpty)
                  Chip(
                    label: Text(
                        'Bonuses: +${payroll.bonuses.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}'),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  ),
                if (payroll.deductions.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Chip(
                    label: Text(
                        'Deductions: -${payroll.deductions.fold(0.0, (a, b) => a + b).toStringAsFixed(0)}'),
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.outlined(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
