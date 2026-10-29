import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/providers/admin_providers.dart';
import 'package:course_emis/widgets/common_state_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClassesScreenRealtime extends ConsumerStatefulWidget {
  const ClassesScreenRealtime({super.key});

  @override
  ConsumerState<ClassesScreenRealtime> createState() =>
      _ClassesScreenRealtimeState();
}

class _ClassesScreenRealtimeState extends ConsumerState<ClassesScreenRealtime> {
  String searchQuery = '';
  String? selectedProgram;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(classesStreamProvider);

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
            child: classesAsync.when(
              data: (classesList) {
                var filtered = classesList.where((c) {
                  final name = c['name']?.toString().toLowerCase() ?? '';
                  final matchesSearch =
                      name.contains(searchQuery.toLowerCase());
                  final matchesProgram = selectedProgram == null ||
                      c['program_id'] == selectedProgram;
                  return matchesSearch && matchesProgram;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.class_outlined,
                    title: t(LCrud.noClassesFound, ref),
                    subtitle: t(LCrud.tryAdjustSearch, ref),
                    onRefresh: () => ref.invalidate(classesStreamProvider),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final classItem = filtered[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.indigo[100],
                          child: Icon(Icons.class_, color: Colors.indigo[700]),
                        ),
                        title: Text(classItem['name']?.toString() ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${classItem['grade']} â€¢ ${classItem['year']}'),
                            Text(
                                'Students: ${classItem['student_count'] ?? 0}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (classItem['active'] == true)
                                    ? Colors.blue[100]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (classItem['active'] == true)
                                    ? t(LCrud.active, ref)
                                    : t(LCrud.inactive, ref),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: (classItem['active'] == true)
                                      ? Colors.blue[700]
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditClassDialog(classItem);
                                } else if (value == 'delete') {
                                  _showDeleteClassConfirmation(classItem);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.edit, size: 20),
                                      const SizedBox(width: 8),
                                      Text(t(L.edit, ref)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.delete, size: 20, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _showDetails(classItem),
                      ),
                    );
                  },
                );
              },
              loading: () => LoadingWidget(message: t(L.loading, ref)),
              error: (error, stack) => CustomErrorWidget(
                error: error,
                onRetry: () => ref.invalidate(classesStreamProvider),
                customMessage: t(LGen.somethingWentWrong, ref),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClassDialog,
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addClass, ref)),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> classItem) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                classItem['name']?.toString() ?? 'Unknown',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(t(LCrud.grade, ref), classItem['grade']?.toString() ?? 'N/A'),
              _buildDetailRow(t(LCrud.year, ref), classItem['year']?.toString() ?? 'N/A'),
              _buildDetailRow(t(LCourse.level, ref), '${classItem['student_count']}'),
              _buildDetailRow(t(LCrud.status, ref),
                  (classItem['active'] == true) ? t(LCrud.active, ref) : t(LCrud.inactive, ref)),
              const SizedBox(height: 16),
              Text(
                t(LCrud.notes, ref),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                classItem['notes']?.toString() ?? t(LCrud.placeholder, ref),
                style: TextStyle(color: Colors.grey[700], height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateClassDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const _CreateClassPage(), fullscreenDialog: true),
    );
    if (result == true) {
      ref.invalidate(classesStreamProvider);
    }
  }

  void _showEditClassDialog(Map<String, dynamic> classItem) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => _EditClassPage(classItem: classItem),
          fullscreenDialog: true),
    );
    if (result == true) {
      ref.invalidate(classesStreamProvider);
    }
  }

  void _showDeleteClassConfirmation(Map<String, dynamic> classItem) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LCrud.deleteClass, ref)),
        content: Text(
            t(LCrud.confirmDeleteItem, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t(L.cancel, ref))),
          FilledButton(
            onPressed: () async {
              try {
                final id = classItem['id'];
                await Supabase.instance.client
                    .from('classes')
                    .delete()
                    .eq('id', id);
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(classesStreamProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.classDeleted, ref))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${t(L.error, ref)}: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
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

class _CreateClassPage extends ConsumerStatefulWidget {
  const _CreateClassPage();

  @override
  ConsumerState<_CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends ConsumerState<_CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gradeCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.nameRequired, ref))),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('classes').insert({
        'name': _nameCtrl.text.trim(),
        'grade': _gradeCtrl.text.trim(),
        'year': int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
        'notes': _notesCtrl.text.trim(),
        'active': true,
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
        title: Text(t(LCrud.addClass, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[classes_screen_realtime] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t(LCrud.addClass, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                    labelText: t(LCrud.className, ref),
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _gradeCtrl,
                decoration: InputDecoration(
                    labelText: t(LCrud.grade, ref),
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _yearCtrl,
                decoration: InputDecoration(
                    labelText: t(LCrud.year, ref),
                    border: const OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                    labelText: t(LCrud.notes, ref),
                    border: const OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditClassPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> classItem;

  const _EditClassPage({required this.classItem});

  @override
  ConsumerState<_EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends ConsumerState<_EditClassPage> {
  final _nameCtrl = TextEditingController();
  final _gradeCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.classItem['name']?.toString() ?? '';
    _gradeCtrl.text = widget.classItem['grade']?.toString() ?? '';
    _yearCtrl.text = widget.classItem['year']?.toString() ?? '';
    _notesCtrl.text = widget.classItem['notes']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _gradeCtrl.dispose();
    _yearCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(LCrud.nameRequired, ref))),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('classes').update({
        'name': _nameCtrl.text.trim(),
        'grade': _gradeCtrl.text.trim(),
        'year': int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year,
        'notes': _notesCtrl.text.trim(),
      }).eq('id', widget.classItem['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_nameCtrl.text.trim()} ${t(LCrud.updatedSuccessfully, ref)}')),
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
        title: Text(t(LCrud.editClass, ref)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () { debugPrint('[classes_screen_realtime] Save button CLICKED'); _save(); },
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(t(L.save, ref)),
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
                  labelText: t(LCrud.className, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _gradeCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.grade, ref),
                  border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.year, ref),
                  border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(
                  labelText: t(LCrud.notes, ref),
                  border: const OutlineInputBorder()),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}


