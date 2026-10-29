import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/models/fee_models.dart';
import 'package:course_emis/repositories/fee_repository.dart';
import 'package:course_emis/services/fee_calculator.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

/// Fee Types — categories of fees (Tuition, Admission, Lab, …).
class FeeTypesScreen extends ConsumerStatefulWidget {
  const FeeTypesScreen({super.key});

  @override
  ConsumerState<FeeTypesScreen> createState() => _FeeTypesScreenState();
}

class _FeeTypesScreenState extends ConsumerState<FeeTypesScreen> {
  final _repo = FeeRepository();
  List<FeeType> _types = [];
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
      final data = await _repo.listFeeTypes();
      if (!mounted) return;
      setState(() => _types = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load fee types: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([FeeType? type]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _FeeTypeFormPage(type: type),
        fullscreenDialog: true,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(FeeType type) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete fee type'),
        content: Text(
            'Delete "${type.name}"? This fails if fee structures still use it.'),
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
      await _repo.deleteFeeType(type.id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
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
        title: const Text('Fee Types'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Fee Type'),
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
    if (_types.isEmpty) {
      return Center(
        child: Text('No fee types yet — add your first one.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _types.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final type = _types[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: type.isActive
                  ? Colors.blue.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              child: Icon(
                _iconFor(type.category),
                color: type.isActive ? Colors.blue : Colors.grey,
              ),
            ),
            title: Text(type.name),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (type.category != null)
                    Chip(
                      label: Text(categoryLabel(type.category!)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  if (type.recurrence != null)
                    Chip(
                      label: Text(frequencyLabel(type.recurrence)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.orange.withValues(alpha: 0.15),
                    ),
                  if (!type.isActive)
                    Chip(
                      label: const Text('Inactive'),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.red.withValues(alpha: 0.15),
                    ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openForm(type),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  onPressed: () => _delete(type),
                ),
              ],
            ),
            onTap: () => _openForm(type),
          ),
        );
      },
    );
  }

  IconData _iconFor(String? category) {
    switch (category) {
      case 'tuition':
        return Icons.school_rounded;
      case 'admission':
        return Icons.how_to_reg_rounded;
      case 'lab':
        return Icons.science_rounded;
      case 'library':
        return Icons.local_library_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'exam':
        return Icons.assignment_rounded;
      case 'transport':
        return Icons.directions_bus_rounded;
      case 'hostel':
        return Icons.bed_rounded;
      case 'activity':
        return Icons.celebration_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}

class _FeeTypeFormPage extends StatefulWidget {
  final FeeType? type;
  const _FeeTypeFormPage({this.type});

  @override
  State<_FeeTypeFormPage> createState() => _FeeTypeFormPageState();
}

class _FeeTypeFormPageState extends State<_FeeTypeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  String? _category;
  String? _recurrence;
  bool _isRecurring = false;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.type != null;

  @override
  void initState() {
    super.initState();
    final t = widget.type;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _category = t?.category;
    _recurrence = t?.recurrence;
    _isRecurring = t?.isRecurring ?? false;
    _isActive = t?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = FeeRepository();
      if (_isEdit) {
        await repo.updateFeeType(widget.type!.id, {
          'name': _nameCtrl.text.trim(),
          if (_category != null) 'category': _category,
          'is_recurring': _isRecurring,
          if (_recurrence != null) 'recurrence': _recurrence,
          'is_active': _isActive,
        });
      } else {
        await repo.createFeeType(
          name: _nameCtrl.text.trim(),
          category: _category,
          isRecurring: _isRecurring,
          recurrence: _isRecurring ? _recurrence : null,
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
        title: Text(_isEdit ? 'Edit Fee Type' : 'New Fee Type'),
        actions: [
          TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: feeCategories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(categoryLabel(c))))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring fee'),
              subtitle: const Text(
                  'Generates on a monthly / quarterly / yearly cycle'),
              value: _isRecurring,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _isRecurring = v),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _recurrence,
                decoration: const InputDecoration(
                  labelText: 'Recurrence',
                  border: OutlineInputBorder(),
                ),
                items: feeFrequencies
                    .where((f) => f != 'one_time')
                    .map((f) => DropdownMenuItem(
                        value: f, child: Text(frequencyLabel(f))))
                    .toList(),
                onChanged: (v) => setState(() => _recurrence = v),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Active'),
              value: _isActive,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Saving…'
                  : (_isEdit ? 'Save Changes' : 'Create Fee Type')),
            ),
          ],
        ),
      ),
    );
  }
}
