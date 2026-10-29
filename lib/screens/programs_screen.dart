import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/models/program.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/modern_ui.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  List<Program> _programs = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('programs')
          .select()
          .order('created_at', ascending: false);
      final list = (response as List).map((json) => _mapToProgram(json)).toList();
      setState(() => _programs = list);
    } catch (e) {
      debugPrint('Error loading programs: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Program _mapToProgram(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final code = json['code'] as String? ?? '';
    final duration = json['duration'] as int? ?? 0;

    ProgramType type = ProgramType.CL;
    for (final t in ProgramType.values) {
      if (code.toUpperCase().contains(t.name.toUpperCase())) {
        type = t;
        break;
      }
    }

    final allowed = duration > 0 ? [duration] : [4, 6, 12];
    final pricing = <int, double>{};
    for (final d in allowed) {
      pricing[d] = d <= 4 ? 40000 : (d <= 6 ? 60000 : 120000);
    }

    return Program(
      id: json['id'] as String,
      name: name,
      code: code,
      type: type,
      departmentId: json['department_id'] as String? ?? '',
      allowedDurations: allowed,
      pricing: pricing,
      description: (json['description'] as String?) ?? '',
      isActive: (json['status'] as String?) == 'active',
      enrolledStudents: 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _programs
        .where(
          (program) =>
              program.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
    final activeCount = _programs.where((program) => program.isActive).length;
    final totalStudents = _programs.fold<int>(
        0, (sum, program) => sum + program.enrolledStudents);
    final avgTicket = _programs.isEmpty
        ? 0
        : _programs
                .map((program) => program.pricing.values.first)
                .reduce((a, b) => a + b) /
            _programs.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(t(LNav.programs, ref)),
        actions: [
          IconButton(
            onPressed: _loadPrograms,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProgramDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(t(LCrud.addProgram, ref)),
      ),
      body: InsightBackground(
        maxWidth: 1200,
        child: SafeArea(
          top: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadPrograms,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      InsightHeroCard(
                        eyebrow: 'Academic programs',
                        title: 'Program catalog and enrollment health',
                        subtitle:
                            'Monitor program distribution, fee structure, and student intake across every course track.',
                        accent: const Color(0xFF7C3AED),
                        chips: [
                          InsightStatChip(
                              label: 'Active', value: '$activeCount'),
                          InsightStatChip(
                              label: 'Enrolled', value: '$totalStudents'),
                          InsightStatChip(
                              label: 'Avg. fee', value: 'PKR $avgTicket'),
                        ],
                        actions: [
                          FilledButton.tonalIcon(
                            onPressed: () => context.go('/departments'),
                            icon: const Icon(Icons.account_tree_outlined),
                            label: const Text('Departments'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        decoration: InputDecoration(
                          hintText: t(LCrud.searchHintGeneric, ref),
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16)),
                          filled: true,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(Icons.school_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(t(LCrud.noProgramsFound, ref),
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        )
                      else
                        ...filtered.map((program) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ModernCard(
                                onTap: () => _showProgramDetails(program),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: _getColor(program.type)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              _getIcon(program.type),
                                              color: _getColor(program.type),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(program.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${program.allowedDurations.join(", ")} months',
                                                  style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'PKR ${program.pricing.values.first.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: _getColor(program.type),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: program.isActive
                                                      ? Colors.blue.withValues(
                                                          alpha: 0.1)
                                                      : Colors.grey
                                                          .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  program.isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: program.isActive
                                                        ? Colors.blue
                                                        : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            onPressed: () => _showAddProgramDialog(context, program: program),
                                            icon: const Icon(Icons.edit_outlined),
                                            tooltip: 'Edit',
                                            iconSize: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            onPressed: () => _confirmDelete(context, program),
                                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                                            tooltip: 'Delete',
                                            iconSize: 20,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  void _showAddProgramDialog(BuildContext context, {Program? program}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => _AddEditProgramPage(program: program),
          fullscreenDialog: true),
    );
    if (result == true) {
      _loadPrograms();
    }
  }

  void _confirmDelete(BuildContext context, Program program) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Are you sure you want to delete "${program.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('programs')
                    .delete()
                    .eq('id', program.id);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadPrograms();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Program deleted successfully')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProgramDetails(Program program) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(program.name,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Type', program.type.name),
            _detailRow('Duration', '${program.allowedDurations.join(", ")} months'),
            _detailRow('Fee', 'PKR ${program.pricing.values.first.toStringAsFixed(0)}'),
            _detailRow('Status', program.isActive ? 'Active' : 'Inactive'),
            if (program.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(program.description, style: TextStyle(color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Color _getColor(ProgramType type) {
    switch (type) {
      case ProgramType.CL:
        return Colors.blue;
      case ProgramType.DEL:
        return Colors.blue;
      case ProgramType.TOEFL:
        return Colors.orange;
      case ProgramType.IELTS:
        return Colors.purple;
      case ProgramType.PTE:
        return Colors.teal;
      case ProgramType.SpokenEnglish:
        return Colors.pink;
      case ProgramType.BusinessEnglish:
        return Colors.indigo;
    }
  }

  IconData _getIcon(ProgramType type) {
    switch (type) {
      case ProgramType.CL:
        return Icons.menu_book_rounded;
      case ProgramType.DEL:
        return Icons.language_rounded;
      case ProgramType.TOEFL:
        return Icons.translate_rounded;
      case ProgramType.IELTS:
        return Icons.school_rounded;
      case ProgramType.PTE:
        return Icons.quiz_rounded;
      case ProgramType.SpokenEnglish:
        return Icons.record_voice_over_rounded;
      case ProgramType.BusinessEnglish:
        return Icons.business_center_rounded;
    }
  }
}

class _AddEditProgramPage extends ConsumerStatefulWidget {
  final Program? program;

  const _AddEditProgramPage({this.program});

  @override
  ConsumerState<_AddEditProgramPage> createState() =>
      _AddEditProgramPageState();
}

class _AddEditProgramPageState extends ConsumerState<_AddEditProgramPage> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.program != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameCtrl.text = widget.program!.name;
      _codeCtrl.text = widget.program!.code;
      _durationCtrl.text =
          widget.program!.allowedDurations.firstOrNull?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim(),
        'duration': int.tryParse(_durationCtrl.text.trim()) ?? 0,
        'status': _isEditing
            ? (widget.program!.isActive ? 'active' : 'inactive')
            : 'active',
      };
      if (_isEditing) {
        await Supabase.instance.client
            .from('programs')
            .update(data)
            .eq('id', widget.program!.id);
      } else {
        await Supabase.instance.client.from('programs').insert(data);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'Program updated successfully'
                  : 'Program added successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Edit Program' : t(LCrud.addProgram, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[programs_screen] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(
                    _isEditing ? t(L.save, ref) : t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.programName, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.programCode, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationCtrl,
              decoration: InputDecoration(
                  labelText: '${t(LCourse.duration, ref)} (months)',
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
