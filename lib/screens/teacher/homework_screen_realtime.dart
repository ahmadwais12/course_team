import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class HomeworkScreenRealtime extends ConsumerStatefulWidget {
  const HomeworkScreenRealtime({super.key});

  @override
  ConsumerState<HomeworkScreenRealtime> createState() =>
      _HomeworkScreenRealtimeState();
}

class _HomeworkScreenRealtimeState
    extends ConsumerState<HomeworkScreenRealtime> {
  String searchQuery = '';
  String? selectedClass;

  @override
  Widget build(BuildContext context) {
    final homeworkAsync = ref.watch(homeworkStreamProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search assignments...',
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
                  final searchLower = searchQuery.toLowerCase();
                  final matchesSearch = title.contains(searchLower);
                  final matchesClass =
                      selectedClass == null || hw['class'] == selectedClass;
                  return matchesSearch && matchesClass;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments found',
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
                    final hw = filtered[index];
                    final submissions = hw['submissions'] ?? 0;
                    final totalStudents = hw['total_students'] ?? 0;
                    final progress =
                        totalStudents > 0 ? submissions / totalStudents : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDetails(hw),
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
                                      hw['title']?.toString() ?? 'Untitled',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(hw['status'])
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      hw['status']?.toString() ?? 'Active',
                                      style: TextStyle(
                                        color: _getStatusColor(hw['status']),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Subject: ${hw['subject']}'),
                              Text('Class: ${hw['class']}'),
                              Text('Due: ${_formatDate(hw['due_date'])}'),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                      '$submissions/$totalStudents submissions'),
                                  const Spacer(),
                                  Text('${(progress * 100).toInt()}%'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(progress)),
                              ),
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
                    Text('Error loading assignments: $error'),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(homeworkStreamProvider),
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
        onPressed: () => _showAddHomeworkDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    switch (status.toString().toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'draft':
        return Colors.grey;
      case 'overdue':
        return Colors.red;
      case 'graded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.orange;
    if (progress < 0.7) return Colors.blue;
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

  void _showDetails(Map<String, dynamic> hw) {
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
                hw['title']?.toString() ?? 'Untitled',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Subject', hw['subject']?.toString() ?? 'N/A'),
              _buildDetailRow('Class', hw['class']?.toString() ?? 'N/A'),
              _buildDetailRow('Due Date', _formatDate(hw['due_date'])),
              _buildDetailRow('Status', hw['status']?.toString() ?? 'Active'),
              _buildDetailRow('Submissions',
                  '${hw['submissions'] ?? 0}/${hw['total_students'] ?? 0}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('View submissions feature')),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Submissions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Edit assignment')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
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

  void _showAddHomeworkDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateAssignmentRTPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }
}

class _CreateAssignmentRTPage extends ConsumerStatefulWidget {
  const _CreateAssignmentRTPage();

  @override
  ConsumerState<_CreateAssignmentRTPage> createState() => _CreateAssignmentRTPageState();
}

class _CreateAssignmentRTPageState extends ConsumerState<_CreateAssignmentRTPage> {
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
    final title = _titleCtrl.text;
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final dueDate = DateTime.tryParse(_dueDateCtrl.text) ??
        DateTime.now().add(const Duration(days: 7));
    try {
      await Supabase.instance.client.from('homework').insert({
        'title': title,
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
          const SnackBar(content: Text('Assignment created successfully')),
        );
        ref.invalidate(homeworkStreamProvider);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create assignment: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Assignment'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () { debugPrint('[homework_screen_realtime] Save button CLICKED'); _save(); },
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
            const SizedBox(height: 12),
            TextField(
              controller: _dueDateCtrl,
              decoration: const InputDecoration(
                labelText: 'Due Date (yyyy-mm-dd)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
