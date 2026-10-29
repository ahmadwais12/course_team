import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class ExamResultsScreen extends ConsumerStatefulWidget {
  const ExamResultsScreen({super.key});

  @override
  ConsumerState<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends ConsumerState<ExamResultsScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(examResultsProvider);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Exam Results')),
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
            child: resultsAsync.when(
              data: (results) {
                var filtered = results.where((r) {
                  final exam = r['exam_name']?.toString().toLowerCase() ?? '';
                  final subject = r['subject']?.toString().toLowerCase() ?? '';
                  final searchLower = searchQuery.toLowerCase();
                  return exam.contains(searchLower) ||
                      subject.contains(searchLower);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(t(LCrud.noResultsFound, ref),
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
                    final result = filtered[index];
                    final percentage = result['percentage'] ?? 0.0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: percentage >= 80
                              ? Colors.blue
                              : percentage >= 50
                                  ? Colors.orange
                                  : Colors.red,
                          child: Text('${percentage.toInt()}%',
                              style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(
                            result['exam_name']?.toString() ?? 'Unknown Exam'),
                        subtitle: Text(
                            '${result['class']} • ${result['subject']} • Pass Rate: ${result['pass_rate'] ?? 'N/A'}%'),
                        trailing: IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _showDetails(result),
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
                      onPressed: () => ref.invalidate(examResultsProvider),
                      icon: const Icon(Icons.refresh),
                      label: Text(t(L.retry, ref)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddResultDialog(),
        icon: const Icon(Icons.add),
        label: Text(t(LCrud.addExamResult, ref)),
      ),
    );
  }

  void _showAddResultDialog() {
    final examNameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final classNameCtrl = TextEditingController();
    final scoreCtrl = TextEditingController();
    final totalMarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t(LCrud.addExamResult, ref)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: examNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Exam Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Subject', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: classNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Class', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: scoreCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Score', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: totalMarksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Total Marks', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t(L.cancel, ref))),
          ElevatedButton(
            onPressed: () async {
              if (examNameCtrl.text.isEmpty ||
                  subjectCtrl.text.isEmpty ||
                  classNameCtrl.text.isEmpty) {
                return;
              }
              Navigator.pop(context);
              try {
                final score = double.tryParse(scoreCtrl.text) ?? 0;
                final totalMarks = double.tryParse(totalMarksCtrl.text) ?? 100;
                final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;
                await Supabase.instance.client.from('exam_results').insert({
                  'exam_name': examNameCtrl.text,
                  'subject': subjectCtrl.text,
                  'class': classNameCtrl.text,
                  'score': score,
                  'total_marks': totalMarks,
                  'percentage': percentage,
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(LCrud.savedSuccessfully, ref))),
                  );
                  ref.invalidate(examResultsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add results: $e')),
                  );
                }
              }
            },
            child: Text(t(L.save, ref)),
          ),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['exam_name']?.toString() ?? 'Unknown',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildRow('Subject', result['subject']?.toString() ?? 'N/A'),
              _buildRow('Class', result['class']?.toString() ?? 'N/A'),
              _buildRow('Score',
                  '${result['score']}/${result['total_marks']}'),
              _buildRow('Percentage',
                  '${(result['percentage'] ?? 0.0).toStringAsFixed(1)}%'),
              _buildRow('Pass Rate',
                  '${result['pass_rate']?.toString() ?? 'N/A'}%'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 120,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}


