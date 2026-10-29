import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/admin_providers.dart';
import 'package:course_emis/widgets/common_state_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProgramsScreenRealtime extends ConsumerStatefulWidget {
  const ProgramsScreenRealtime({super.key});

  @override
  ConsumerState<ProgramsScreenRealtime> createState() =>
      _ProgramsScreenRealtimeState();
}

class _ProgramsScreenRealtimeState
    extends ConsumerState<ProgramsScreenRealtime> {
  String searchQuery = '';
  String? selectedDepartment;

  @override
  Widget build(BuildContext context) {
    final programsAsync = ref.watch(programsStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: t(LCrud.searchHintGeneric, ref),
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: programsAsync.when(
              data: (programs) {
                var filtered = programs.where((p) {
                  final name = p['name']?.toString().toLowerCase() ?? '';
                  final code = p['code']?.toString().toLowerCase() ?? '';
                  final matchesSearch =
                      name.contains(searchQuery.toLowerCase()) ||
                          code.contains(searchQuery.toLowerCase());
                  final matchesDept = selectedDepartment == null ||
                      p['department_id'] == selectedDepartment;
                  return matchesSearch && matchesDept;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.school_outlined,
                    title: t(LCrud.noProgramsFound, ref),
                    subtitle: t(LCrud.tryAdjustSearch, ref),
                    onRefresh: () => ref.invalidate(programsStreamProvider),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final program = filtered[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDetails(program),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.menu_book,
                                  color: Colors.blue[700],
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      program['name']?.toString() ?? 'Untitled',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${program['code']} â€¢ ${program['duration'] ?? 'N/A'}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(
                                            '${program['credits']} Credits',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white),
                                          ),
                                          backgroundColor: Colors.blue,
                                          padding: EdgeInsets.zero,
                                        ),
                                        if (program['status'] != null)
                                          Chip(
                                            label: Text(
                                              program['status'],
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white),
                                            ),
                                            backgroundColor: _getStatusColor(
                                                program['status']),
                                            padding: EdgeInsets.zero,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  LoadingWidget(message: t(L.loading, ref)),
              error: (error, stack) => CustomErrorWidget(
                error: error,
                onRetry: () => ref.invalidate(programsStreamProvider),
                customMessage: t(LGen.tryAgain, ref),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProgramDialog,
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addProgram, ref)),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showCreateProgramDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const _CreateProgramPage(), fullscreenDialog: true),
    );
    if (result == true) {
      ref.invalidate(programsStreamProvider);
    }
  }

  void _showDetails(Map<String, dynamic> program) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                program['name']?.toString() ?? 'Untitled',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(t(LCrud.programCode, ref), program['code']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  t(LCourse.duration, ref), program['duration']?.toString() ?? 'N/A'),
              _buildDetailRow(t(LCourse.level, ref), '${program['credits']}'),
              _buildDetailRow(
                  t(LCrud.status, ref), program['status']?.toString() ?? t(LCrud.active, ref)),
              const SizedBox(height: 16),
              Text(
                t(LCrud.description, ref),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                program['description']?.toString() ?? t(LCrud.placeholder, ref),
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CreateProgramPage extends ConsumerStatefulWidget {
  const _CreateProgramPage();

  @override
  ConsumerState<_CreateProgramPage> createState() => _CreateProgramPageState();
}

class _CreateProgramPageState extends ConsumerState<_CreateProgramPage> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _creditsCtrl = TextEditingController(text: '0');
  String _status = 'active';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _durationCtrl.dispose();
    _descriptionCtrl.dispose();
    _creditsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _codeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.nameRequired, ref))),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('programs').insert({
        'name': _nameCtrl.text.trim(),
        'code': _codeCtrl.text.trim().toUpperCase(),
        'duration': _durationCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'credits': int.tryParse(_creditsCtrl.text.trim()) ?? 0,
        'status': _status,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_nameCtrl.text.trim()} ${t(LCrud.createdSuccessfully, ref)}')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${t(L.error, ref)}: $e'),
              backgroundColor: Colors.red),
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
        title: Text(t(LCrud.addProgram, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[programs_screen_realtime] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t(L.add, ref)),
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
                  labelText: t(LCourse.duration, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.description, ref),
                  border: const OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _creditsCtrl,
              decoration: InputDecoration(
                  labelText: t(LCourse.level, ref),
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
initialValue: _status,
              decoration: InputDecoration(
                  labelText: t(LCrud.status, ref),
                  border: const OutlineInputBorder()),
              items: ['active', 'inactive', 'pending']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? 'active'),
            ),
          ],
        ),
      ),
    );
  }
}
