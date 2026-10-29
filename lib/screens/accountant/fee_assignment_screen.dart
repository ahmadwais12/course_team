import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/models/fee_models.dart';
import 'package:course_emis/repositories/fee_repository.dart';
import 'package:course_emis/services/fee_calculator.dart';
import 'package:course_emis/utils/money_format.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

/// Assign Fees — pick a student, select fee structures, optionally apply a
/// discount and split into installments.
class FeeAssignmentsScreen extends ConsumerStatefulWidget {
  const FeeAssignmentsScreen({super.key});

  @override
  ConsumerState<FeeAssignmentsScreen> createState() =>
      _FeeAssignmentsScreenState();
}

class _FeeAssignmentsScreenState extends ConsumerState<FeeAssignmentsScreen> {
  final _repo = FeeRepository();

  List<Map<String, dynamic>> _students = [];
  List<FeeStructure> _structures = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _studentId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 15));
  final _discountCtrl = TextEditingController();
  final _discountReasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _useInstallments = false;
  int _installmentCount = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    _discountReasonCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final students = await _repo.listStudents();
      final structures = await _repo.listFeeStructures(onlyActive: true);
      if (!mounted) return;
      setState(() {
        _students = students;
        _structures = structures;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  double get _discountPercent =>
      double.tryParse(_discountCtrl.text) ?? 0;

  double get _grossTotal =>
      _structures.where((s) => _selectedIds.contains(s.id)).fold<double>(
          0, (sum, s) => sum + s.amount);

  double get _netTotal => _grossTotal * (1 - _discountPercent / 100);

  Future<void> _assign() async {
    if (_studentId == null) {
      _snack('Please select a student.');
      return;
    }
    if (_selectedIds.isEmpty) {
      _snack('Select at least one fee structure.');
      return;
    }
    if (_discountPercent < 0 || _discountPercent > 100) {
      _snack('Discount must be between 0 and 100%.');
      return;
    }
    setState(() => _saving = true);
    try {
      final chosen =
          _structures.where((s) => _selectedIds.contains(s.id)).toList();
      final created = await _repo.assignFees(
        studentId: _studentId!,
        structures: chosen,
        dueDate: _dueDate,
        discountPercent: _discountPercent,
        discountReason:
            _discountReasonCtrl.text.trim().isEmpty ? null : _discountReasonCtrl.text.trim(),
        installmentCount: _useInstallments ? _installmentCount : null,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Assigned ${created.length} fee(s) totalling ${fmtMoney(_netTotal)}.')));
      setState(() => _selectedIds.clear());
    } catch (e) {
      if (!mounted) return;
      _snack('Assign failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Assign Fees to Student'),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) return const ListSkeleton(itemCount: 5);
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Student + due date ────────────────────────────────────────────
        DropdownButtonFormField<String>(
          initialValue: _studentId,
          decoration: const InputDecoration(
              labelText: 'Student *', border: OutlineInputBorder()),
          items: _students
              .map((s) => DropdownMenuItem(
                    value: s['id'] as String,
                    child: Text(
                        '${s['full_name'] ?? 'Unknown'}'
                        '${(s['student_code'] as String?) != null ? ' (${s['student_code']})' : ''}'),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _studentId = v),
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: Text('Due date: ${_dateLabel(_dueDate)}'),
          trailing: const Icon(Icons.edit_outlined, size: 18),
          onTap: _pickDueDate,
        ),
        const Divider(height: 32),

        // ── Structure picker ──────────────────────────────────────────────
        Text('Fee structures',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Select one or more structures to assign.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        if (_structures.isEmpty)
          const Text('No active fee structures defined yet.')
        else
          ..._structures.map((s) {
            final checked = _selectedIds.contains(s.id);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: checked,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(s.name),
                subtitle: Text(
                  '${s.feeTypeName ?? ''} • ${fmtMoney(s.amount, currency: s.currency)}'
                  '${s.frequency != null ? ' • ${frequencyLabel(s.frequency)}' : ''}',
                ),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedIds.add(s.id);
                  } else {
                    _selectedIds.remove(s.id);
                  }
                }),
              ),
            );
          }),
        const Divider(height: 32),

        // ── Discount ──────────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _discountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Discount %',
                    border: OutlineInputBorder()),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _discountReasonCtrl,
                decoration: const InputDecoration(
                    labelText: 'Discount reason (optional)',
                    border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
        const Divider(height: 32),

        // ── Installments ──────────────────────────────────────────────────
        SwitchListTile(
          title: const Text('Split into installments'),
          value: _useInstallments,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() => _useInstallments = v),
        ),
        if (_useInstallments) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _installmentCount,
            decoration: const InputDecoration(
                labelText: 'Number of installments',
                border: OutlineInputBorder()),
            items: [
              for (var i = 2; i <= 12; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _installmentCount = v);
            },
          ),
        ],
        const Divider(height: 32),

        // ── Notes + summary ───────────────────────────────────────────────
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
              labelText: 'Notes (optional)', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        Card(
          color: theme.colorScheme.primary.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow('Structures selected', '${_selectedIds.length}'),
                const Divider(height: 12),
                _summaryRow('Total before discount',
                    fmtAmount(_grossTotal)),
                if (_discountPercent > 0)
                  _summaryRow(
                      'Discount ($_discountPercent%)', '−${fmtAmount(_grossTotal - _netTotal)}'),
                _summaryRow(
                  'Net total',
                  fmtMoney(_netTotal),
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _saving ? null : _assign,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_saving ? 'Assigning…' : 'Assign Fees'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/fee-statement'),
          child: const Text('View student fee statements instead'),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }

  String _dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
