import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class LessonPlansScreenRealtime extends ConsumerStatefulWidget {
  const LessonPlansScreenRealtime({super.key});

  @override
  ConsumerState<LessonPlansScreenRealtime> createState() =>
      _LessonPlansScreenRealtimeState();
}

class _LessonPlansScreenRealtimeState
    extends ConsumerState<LessonPlansScreenRealtime> {
  String searchQuery = '';
  String? selectedClass;

  @override
  Widget build(BuildContext context) {
    final lessonPlansAsync = ref.watch(lessonPlansStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search lesson plans...',
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
                // Filter by search and class
                var filtered = lessonPlans.where((lp) {
                  final title = lp['title']?.toString().toLowerCase() ?? '';
                  final subject = lp['subject']?.toString().toLowerCase() ?? '';
                  final searchLower = searchQuery.toLowerCase();
                  final matchesSearch = title.contains(searchLower) ||
                      subject.contains(searchLower);
                  final matchesClass =
                      selectedClass == null || lp['class'] == selectedClass;
                  return matchesSearch && matchesClass;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No lesson plans found',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final lp = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDetails(lp),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      lp['title']?.toString() ?? 'Untitled',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(lp['status'])
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      lp['status']?.toString() ?? 'Draft',
                                      style: TextStyle(
                                        color: _getStatusColor(lp['status']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Subject: ${lp['subject']}'),
                              Text('Class: ${lp['class']}'),
                              Text('Date: ${_formatDate(lp['date'])}'),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (lp['completion'] ?? 0) / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(lp['completion'] ?? 0)),
                              ),
                              const SizedBox(height: 4),
                              Text('${lp['completion'] ?? 0}% complete'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const PageSkeleton(type: 'list'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error loading lesson plans: $error',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(lessonPlansStreamProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLessonPlanDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'planned':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 50) return Colors.orange;
    if (progress < 80) return Colors.blue;
    return Colors.blue;
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

  void _showDetails(Map<String, dynamic> lp) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp['title']?.toString() ?? 'Untitled',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Subject', lp['subject']?.toString() ?? 'N/A'),
              _buildDetailRow('Class', lp['class']?.toString() ?? 'N/A'),
              _buildDetailRow('Date', _formatDate(lp['date'])),
              _buildDetailRow('Status', lp['status']?.toString() ?? 'Draft'),
              _buildDetailRow('Completion', '${lp['completion'] ?? 0}%'),
              const SizedBox(height: 16),
              Text('Objectives:',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(lp['objectives']?.toString() ?? 'No objectives specified'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Edit lesson plan feature')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share lesson plan')),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ),
                ],
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

  void _showAddLessonPlanDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateLessonPlanRTPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _CreateLessonPlanRTPage extends ConsumerStatefulWidget {
  const _CreateLessonPlanRTPage();

  @override
  ConsumerState<_CreateLessonPlanRTPage> createState() => _CreateLessonPlanRTPageState();
}

class _CreateLessonPlanRTPageState extends ConsumerState<_CreateLessonPlanRTPage> {
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _classCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subjectCtrl.dispose();
    _classCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text;
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('lesson_plans').insert({
        'title': title,
        'subject': _subjectCtrl.text,
        'class': _classCtrl.text,
        'status': 'Draft',
        'completion': 0,
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson plan created successfully')),
        );
        ref.invalidate(lessonPlansStreamProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create lesson plan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Lesson Plan'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[lesson_plans_screen_realtime] Save button CLICKED'); _save(); },
            child: const Text('Create'),
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
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectCtrl,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _classCtrl,
              decoration: const InputDecoration(
                labelText: 'Class',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
