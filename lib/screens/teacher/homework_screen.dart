import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({super.key});

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final homeworkAsync = ref.watch(homeworkProvider);

    return Column(
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
          child: homeworkAsync.when(
            data: (homeworkList) {
              var filtered = homeworkList.where((hw) {
                final title = hw['title']?.toString().toLowerCase() ?? '';
                return title.contains(searchQuery.toLowerCase());
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(t(LCrud.noItemsFound, ref),
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final hw = filtered[index];
                  final submissions = hw['submissions'] ?? 0;
                  final totalStudents = hw['total_students'] ?? 0;
                  final progress = totalStudents > 0
                      ? submissions / totalStudents
                      : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: hw['status'] == 'Active'
                                      ? Colors.blue[100]
                                      : Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  hw['status']?.toString() ?? 'Active',
                                  style: TextStyle(
                                    color: hw['status'] == 'Active'
                                        ? Colors.blue[800]
                                        : Colors.red[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert),
                                onPressed: () => _showOptions(hw),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            hw['title']?.toString() ?? 'Untitled',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                  '${hw['class']} • ${hw['subject']}'),
                              const SizedBox(width: 16),
                              Text(tt(LAll.all_due_x, ref,
                                  [_formatDate(hw['due_date'])])),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      '$submissions/$totalStudents submissions'),
                                  Text(tt(LAll.all_s3, ref,
                                      ['${(progress * 100).toInt()}'])),
                                ],
                              ),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  hw['status'] == 'Overdue'
                                      ? Colors.red
                                      : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(tt(LAll.all_error_x, ref, ['$error'])),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(homeworkProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(t(L.retry, ref)),
                  ),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          icon: const Icon(Icons.add),
          label: Text(t(LCrud.assignHomework, ref)),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not set';
    DateTime dt;
    if (date is String) {
      dt = DateTime.parse(date);
    } else if (date is DateTime) {
      dt = date;
    } else {
      return 'Not set';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showAddDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AssignHomeworkPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showOptions(Map<String, dynamic> hw) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(t(LCrud.viewSubmissions, ref)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(t(L.edit, ref)),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(hw);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(t(L.delete, ref), style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(hw['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> hw) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditHomeworkPage(hw: hw),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LCrud.confirmDelete, ref)),
        content: Text(t(LAll.all_are_you_sure, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t(L.cancel, ref))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('homework')
                    .delete()
                    .eq('id', id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(t(LCrud.deletedSuccessfully, ref))),
                  );
                  ref.invalidate(homeworkProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(tt(LAll.all_failed_to_delete_x, ref,
                            ['$e']))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );
  }
}

class _AssignHomeworkPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AssignHomeworkPage> createState() => _AssignHomeworkPageState();
}

class _AssignHomeworkPageState extends ConsumerState<_AssignHomeworkPage> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      final dueDate = DateTime.tryParse(_dueDateCtrl.text) ??
          DateTime.now().add(const Duration(days: 7));
      await Supabase.instance.client.from('homework').insert({
        'title': _titleCtrl.text,
        'subject': _subjectCtrl.text,
        'class': _classCtrl.text,
        'due_date': dueDate.toIso8601String(),
        'status': 'Active',
        'submissions': 0,
        'total_students': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LCrud.savedSuccessfully, ref))),
        );
        ref.invalidate(homeworkProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tt(LAll.all_failed_to_assign_homework_x, ref,
                  ['$e']))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.assignHomework, ref)),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[homework_screen] Save button CLICKED'); _save(); },
            child: Text(t(LFlow.assign, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _classCtrl,
                decoration: const InputDecoration(
                    labelText: 'Class', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _dueDateCtrl,
                decoration: const InputDecoration(
                    labelText: 'Due Date (yyyy-mm-dd)',
                    border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}

class _EditHomeworkPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> hw;
  const _EditHomeworkPage({required this.hw});

  @override
  ConsumerState<_EditHomeworkPage> createState() => _EditHomeworkPageState();
}

class _EditHomeworkPageState extends ConsumerState<_EditHomeworkPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subjectCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.hw['title']?.toString());
    _subjectCtrl = TextEditingController(text: widget.hw['subject']?.toString());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client
          .from('homework')
          .update({
            'title': _titleCtrl.text,
            'subject': _subjectCtrl.text,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.hw['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t(LCrud.updatedSuccessfully, ref))),
        );
        ref.invalidate(homeworkProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(tt(LAll.all_failed_to_update_x, ref, ['$e']))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(L.edit, ref)),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[homework_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _subjectCtrl,
                decoration: const InputDecoration(
                    labelText: 'Subject', border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}


