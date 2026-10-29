import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class LessonPlansScreen extends ConsumerStatefulWidget {
  const LessonPlansScreen({super.key});

  @override
  ConsumerState<LessonPlansScreen> createState() => _LessonPlansScreenState();
}

class _LessonPlansScreenState extends ConsumerState<LessonPlansScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final lessonPlansAsync = ref.watch(lessonPlansProvider);

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
          child: lessonPlansAsync.when(
            data: (lessonPlans) {
              var filtered = lessonPlans.where((plan) {
                final title = plan['title']?.toString().toLowerCase() ?? '';
                final subject =
                    plan['subject']?.toString().toLowerCase() ?? '';
                final searchLower = searchQuery.toLowerCase();
                return title.contains(searchLower) ||
                    subject.contains(searchLower);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No lesson plans found',
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
                  final plan = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(plan['status']),
                        child: Icon(Icons.book, color: Colors.white),
                      ),
                      title: Text(plan['title']?.toString() ?? 'Untitled'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(plan['subject']?.toString() ?? ''),
                          Text(
                              '${_formatDate(plan['date'])} • ${plan['duration'] ?? ''}'),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              value: 'edit', child: Text(t(L.edit, ref))),
                          PopupMenuItem(
                              value: 'delete', child: Text(t(L.delete, ref))),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') _showEditDialog(plan);
                          if (value == 'delete') _confirmDelete(plan['id']);
                        },
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: $error'),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(lessonPlansProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _showAddDialog(),
          icon: const Icon(Icons.add),
          label: const Text('New Plan'),
        ),
      ],
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status?.toString().toLowerCase() ?? '') {
      case 'completed':
        return Colors.blue;
      case 'in progress':
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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
        builder: (_) => _AddLessonPlanPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _showEditDialog(Map<String, dynamic> plan) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditLessonPlanPage(plan: plan),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _confirmDelete(dynamic id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lesson Plan'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('lesson_plans')
                    .delete()
                    .eq('id', id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Lesson plan deleted successfully')),
                  );
                  ref.invalidate(lessonPlansProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddLessonPlanPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AddLessonPlanPage> createState() => _AddLessonPlanPageState();
}

class _AddLessonPlanPageState extends ConsumerState<_AddLessonPlanPage> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _objectivesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _durationCtrl.dispose();
    _objectivesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('lesson_plans').insert({
        'title': _titleCtrl.text,
        'subject': _subjectCtrl.text,
        'duration': _durationCtrl.text,
        'objectives': _objectivesCtrl.text
                .split('\n')
                .where((l) => l.trim().isNotEmpty)
                .toList(),
        'status': 'Planned',
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson plan saved successfully')),
        );
        ref.invalidate(lessonPlansProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Lesson Plan'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[lesson_plans_screen] Save button CLICKED'); _save(); },
            child: const Text('Save'),
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
                controller: _durationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Duration (e.g. 90 minutes)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
                controller: _objectivesCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Objectives (one per line)',
                    border: OutlineInputBorder())),
          ],
        ),
      ),
    );
  }
}

class _EditLessonPlanPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> plan;
  const _EditLessonPlanPage({required this.plan});

  @override
  ConsumerState<_EditLessonPlanPage> createState() => _EditLessonPlanPageState();
}

class _EditLessonPlanPageState extends ConsumerState<_EditLessonPlanPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subjectCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.plan['title']?.toString());
    _subjectCtrl = TextEditingController(text: widget.plan['subject']?.toString());
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
          .from('lesson_plans')
          .update({
            'title': _titleCtrl.text,
            'subject': _subjectCtrl.text,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.plan['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson plan updated successfully')),
        );
        ref.invalidate(lessonPlansProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Lesson Plan'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[lesson_plans_screen] Save button CLICKED'); _save(); },
            child: const Text('Save'),
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


