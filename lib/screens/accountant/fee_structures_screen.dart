import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/models/fee_models.dart';
import 'package:course_emis/repositories/fee_repository.dart';
import 'package:course_emis/services/fee_calculator.dart';
import 'package:course_emis/utils/money_format.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

/// Fee Structures — amounts attached to a fee type, program and/or class.
class FeeStructuresScreen extends ConsumerStatefulWidget {
  const FeeStructuresScreen({super.key});

  @override
  ConsumerState<FeeStructuresScreen> createState() =>
      _FeeStructuresScreenState();
}

class _FeeStructuresScreenState extends ConsumerState<FeeStructuresScreen> {
  final _repo = FeeRepository();
  List<FeeStructure> _structures = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.listFeeStructures();
      if (!mounted) return;
      setState(() => _structures = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load fee structures: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([FeeStructure? structure]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _FeeStructureFormPage(structure: structure),
        fullscreenDialog: true,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(FeeStructure structure) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete fee structure'),
        content: Text(
            'Delete "${structure.name}"? This fails if it is already assigned to students.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteFeeStructure(structure.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Fee Structures'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Structure'),
      ),
      body: _buildBody(Theme.of(context)),
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
    if (_structures.isEmpty) {
      return Center(
        child: Text('No fee structures yet — define fee amounts first.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _structures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _structures[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.teal.withValues(alpha: 0.15),
              child: Text(
                s.feeTypeName != null && s.feeTypeName!.isNotEmpty
                    ? s.feeTypeName![0].toUpperCase()
                    : 'F',
                style: const TextStyle(color: Colors.teal),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(s.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(fmtMoney(s.amount, currency: s.currency),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (s.feeTypeName != null)
                    _chip(s.feeTypeName!, Colors.blue),
                  if (s.frequency != null)
                    _chip(frequencyLabel(s.frequency), Colors.orange),
                  if (s.programName != null)
                    _chip('Program: ${s.programName}', Colors.purple),
                  if (s.className != null)
                    _chip('Class: ${s.className}', Colors.indigo),
                  if (s.dueDay != null) _chip('Due day ${s.dueDay}', Colors.teal),
                  if (s.lateFee > 0)
                    _chip('Late fee ${fmtAmount(s.lateFee)}${s.lateFeeType == 'percentage' ? '%' : ''}',
                        Colors.red),
                  if (!s.isActive)
                    _chip('Inactive', Colors.grey),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openForm(s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => _delete(s),
                ),
              ],
            ),
            onTap: () => _openForm(s),
          ),
        );
      },
    );
  }

  Widget _chip(String text, Color color) => Chip(
        label: Text(text),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: color.withValues(alpha: 0.12),
        labelStyle: TextStyle(fontSize: 11, color: color),
      );
}

class _FeeStructureFormPage extends StatefulWidget {
  final FeeStructure? structure;
  const _FeeStructureFormPage({this.structure});

  @override
  State<_FeeStructureFormPage> createState() => _FeeStructureFormPageState();
}

class _FeeStructureFormPageState extends State<_FeeStructureFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _lateFeeCtrl;
  late final TextEditingController _earlyBirdCtrl;
  late final TextEditingController _groupCtrl;

  List<FeeType> _feeTypes = [];
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _classes = [];

  String? _feeTypeId;
  String? _programId;
  String? _classId;
  String? _frequency;
  String? _lateFeeType;
  int? _dueDay;
  bool _isActive = true;
  bool _loadingRefs = true;
  bool _saving = false;

  bool get _isEdit => widget.structure != null;

  @override
  void initState() {
    super.initState();
    final s = widget.structure;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _amountCtrl =
        TextEditingController(text: s != null ? s.amount.toString() : '');
    _lateFeeCtrl =
        TextEditingController(text: s != null ? s.lateFee.toString() : '');
    _earlyBirdCtrl = TextEditingController(
        text: s != null ? s.earlyBirdDiscount.toString() : '');
    _groupCtrl =
        TextEditingController(text: s != null ? s.groupDiscount.toString() : '');
    _feeTypeId = s?.feeTypeId;
    _programId = s?.programId;
    _classId = s?.classId;
    _frequency = s?.frequency;
    _lateFeeType = s?.lateFeeType;
    _dueDay = s?.dueDay;
    _isActive = s?.isActive ?? true;
    _loadRefs();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _lateFeeCtrl.dispose();
    _earlyBirdCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRefs() async {
    final repo = FeeRepository();
    try {
      final types = await repo.listFeeTypes();
      final programs = await repo.listPrograms();
      final classes = await repo.listClasses();
      if (!mounted) return;
      setState(() {
        // Include inactive types too so editing an existing structure whose
        // fee type was later deactivated still has a valid dropdown item.
        _feeTypes = types;
        _programs = programs;
        _classes = classes;
        _loadingRefs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRefs = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load references: $e')));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = FeeRepository();
      final amount = double.tryParse(_amountCtrl.text) ?? 0;
      final lateFee = double.tryParse(_lateFeeCtrl.text) ?? 0;
      final earlyBird = double.tryParse(_earlyBirdCtrl.text) ?? 0;
      final group = double.tryParse(_groupCtrl.text) ?? 0;

      if (_isEdit) {
        await repo.updateFeeStructure(widget.structure!.id, {
          'name': _nameCtrl.text.trim(),
          if (_feeTypeId != null) 'fee_type_id': _feeTypeId,
          if (_programId != null) 'program_id': _programId,
          if (_classId != null) 'class_id': _classId,
          'amount': amount,
          if (_frequency != null) 'frequency': _frequency,
          if (_dueDay != null) 'due_day': _dueDay,
          'late_fee': lateFee,
          if (_lateFeeType != null) 'late_fee_type': _lateFeeType,
          'early_bird_discount': earlyBird,
          'group_discount': group,
          'is_active': _isActive,
        });
      } else {
        await repo.createFeeStructure(
          name: _nameCtrl.text.trim(),
          feeTypeId: _feeTypeId,
          programId: _programId,
          classId: _classId,
          amount: amount,
          frequency: _frequency,
          dueDay: _dueDay,
          lateFee: lateFee,
          lateFeeType: _lateFeeType,
          earlyBirdDiscount: earlyBird,
          groupDiscount: group,
          isActive: _isActive,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Fee Structure' : 'New Fee Structure'),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel')),
        ],
      ),
      body: _loadingRefs
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name', border: OutlineInputBorder()),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _feeTypeId,
                          decoration: const InputDecoration(
                              labelText: 'Fee Type *',
                              border: OutlineInputBorder()),
                          items: _feeTypes
                              .map((t) => DropdownMenuItem(
                                  value: t.id, child: Text(t.name)))
                              .toList(),
                          onChanged: (v) => setState(() => _feeTypeId = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Amount *',
                              prefixText: 'AFN ',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (double.tryParse(v ?? '') ?? 0) <= 0
                                  ? 'Enter amount'
                                  : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder()),
                    items: feeFrequencies
                        .map((f) => DropdownMenuItem(
                            value: f, child: Text(frequencyLabel(f))))
                        .toList(),
                    onChanged: (v) => setState(() => _frequency = v),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _programId,
                          decoration: const InputDecoration(
                              labelText: 'Program (optional)',
                              border: OutlineInputBorder()),
                          items: _programs
                              .map((p) => DropdownMenuItem(
                                  value: p['id'] as String,
                                  child: Text(
                                      (p['name'] as String?) ?? 'Unknown')))
                              .toList(),
                          onChanged: (v) => setState(() => _programId = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _classId,
                          decoration: const InputDecoration(
                              labelText: 'Class (optional)',
                              border: OutlineInputBorder()),
                          items: _classes
                              .map((c) => DropdownMenuItem(
                                  value: c['id'] as String,
                                  child: Text(
                                      (c['name'] as String?) ?? 'Unknown')))
                              .toList(),
                          onChanged: (v) => setState(() => _classId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lateFeeCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Late fee',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _lateFeeType,
                          decoration: const InputDecoration(
                              labelText: 'Late fee type',
                              border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(
                                value: 'fixed', child: Text('Fixed')),
                            DropdownMenuItem(
                                value: 'percentage', child: Text('Percentage')),
                          ],
                          onChanged: (v) => setState(() => _lateFeeType = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _earlyBirdCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Early-bird %',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _groupCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Group discount %',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _dueDay,
                          decoration: const InputDecoration(
                              labelText: 'Due day',
                              border: OutlineInputBorder()),
                          items: [
                            for (var d = 1; d <= 31; d++)
                              DropdownMenuItem(value: d, child: Text('$d')),
                          ],
                          onChanged: (v) => setState(() => _dueDay = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving
                        ? 'Saving…'
                        : (_isEdit ? 'Save Changes' : 'Create Structure')),
                  ),
                ],
              ),
            ),
    );
  }
}
