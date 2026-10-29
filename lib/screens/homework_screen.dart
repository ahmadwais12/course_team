import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({super.key});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  List<Map<String, dynamic>> _homework = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    try {
      final data = await Supabase.instance.client
          .from('homework')
          .select()
          .order('created_at', ascending: false);
      if (mounted) setState(() => _homework = List<Map<String, dynamic>>.from(data));
    } catch (_) {
      if (mounted) setState(() => _homework = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homework & Assignments')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddHomework(context),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _homework.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.assignment, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No homework assignments.', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHomework,
                  child: ListView(
                    padding: AppSpacing.paddingLg,
                    children: _homework.map((h) {
                      final status = h['status']?.toString() ?? 'Pending';
                      final color = status.toLowerCase() == 'submitted' ? Colors.blue : Colors.orange;
                      return _HomeworkCard(
                        title: h['title']?.toString() ?? 'Untitled',
                        subject: h['subject']?.toString() ?? '',
                        dueDate: _formatDate(h['due_date']?.toString()),
                        status: status,
                        color: color,
                      );
                    }).toList(),
                  ),
                ),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.length < 10) return date ?? '';
    return date.substring(0, 10);
  }

  void _showAddHomework(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AddHomeworkPage(onAdded: () {
          if (mounted) _loadHomework();
        }),
        fullscreenDialog: true,
      ),
    );
  }
}

class _AddHomeworkPage extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddHomeworkPage({required this.onAdded});

  @override
  State<_AddHomeworkPage> createState() => _AddHomeworkPageState();
}

class _AddHomeworkPageState extends State<_AddHomeworkPage> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _dueCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _dueCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Homework'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 12),
          TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 12),
          TextField(controller: _dueCtrl, decoration: const InputDecoration(labelText: 'Due Date')),
          const SizedBox(height: 12),
          TextField(controller: _descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { debugPrint('[homework_screen] Save button CLICKED'); _save(); },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.isEmpty) return;
    await Supabase.instance.client.from('homework').insert({
      'title': _titleCtrl.text,
      'subject': _subjectCtrl.text,
      'due_date': _dueCtrl.text,
      'description': _descCtrl.text,
      'status': 'Pending',
    });
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }
}

class _HomeworkCard extends StatelessWidget {
  final String title;
  final String subject;
  final String dueDate;
  final String status;
  final Color color;

  const _HomeworkCard({
    required this.title,
    required this.subject,
    required this.dueDate,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.book, size: 16, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text(subject, style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 4),
              Text('Due: $dueDate', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/homework'),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.go('/homework'),
                  icon: const Icon(Icons.upload, size: 18),
                  label: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
