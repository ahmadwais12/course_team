import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class ExamResultsScreenRealtime extends ConsumerStatefulWidget {
  const ExamResultsScreenRealtime({super.key});

  @override
  ConsumerState<ExamResultsScreenRealtime> createState() =>
      _ExamResultsScreenRealtimeState();
}

class _ExamResultsScreenRealtimeState
    extends ConsumerState<ExamResultsScreenRealtime> {
  String searchQuery = '';
  String? selectedExam;

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(examResultsStreamProvider);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: Text(t(LExam.examResults, ref))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search results...',
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
                  final student =
                      r['student_name']?.toString().toLowerCase() ?? '';
                  final exam = r['exam_name']?.toString().toLowerCase() ?? '';
                  final searchLower = searchQuery.toLowerCase();
                  return student.contains(searchLower) ||
                      exam.contains(searchLower);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(t(LAll.all_no_exam_results_found, ref),
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
                          backgroundColor:
                              _getGradeColor(result['grade']).withValues(alpha: 0.1),
                          child: Text(
                            result['grade']?.toString() ?? 'N/A',
                            style: TextStyle(
                              color: _getGradeColor(result['grade']),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        title: Text(
                            result['student_name']?.toString() ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${result['exam_name']} • ${result['subject']}'),
                            Text(
                                'Score: ${result['score']}/${result['total_marks']} (${percentage.toStringAsFixed(1)}%)'),
                          ],
                        ),
                        trailing: Text(
                          _formatDate(result['exam_date']),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        onTap: () => _showDetails(result),
                      ),
                    );
                  },
                );
              },
              loading: () => const PageSkeleton(type: 'exams'),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(tt(LAll.all_error_x, ref, [error.toString()])),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(examResultsStreamProvider),
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
        label: Text(t(LAll.all_add_result, ref)),
      ),
    );
  }

  Color _getGradeColor(dynamic grade) {
    switch (grade.toString().toUpperCase()) {
      case 'A':
      case 'A+':
        return Colors.blue;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
      case 'F':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dt;
    if (date is String) {
      dt = DateTime.parse(date);
    } else if (date is DateTime) {
      dt = date;
    } else {
      return '';
    }
    return '${dt.day}/${dt.month}';
  }

  void _showDetails(Map<String, dynamic> result) {
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
                '${result['student_name']} - ${result['exam_name']}',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                  'Subject', result['subject']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  'Score', '${result['score']}/${result['total_marks']}'),
              _buildDetailRow('Percentage',
                  '${(result['percentage'] ?? 0.0).toStringAsFixed(1)}%'),
              _buildDetailRow('Grade', result['grade']?.toString() ?? 'N/A'),
              _buildDetailRow('Date', _formatDate(result['exam_date'])),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(LAll.all_view_detailed_analysis, ref))),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: Text(t(LAll.all_view_analysis, ref)),
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
              child: Text(tt(LAll.all_s560, ref, [label]),
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showAddResultDialog() {
    final examNameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final classNameCtrl = TextEditingController();
    final studentNameCtrl = TextEditingController();
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
                  labelText: 'Exam Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: classNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: studentNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scoreCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Score',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalMarksCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Marks',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              examNameCtrl.dispose();
              subjectCtrl.dispose();
              classNameCtrl.dispose();
              studentNameCtrl.dispose();
              scoreCtrl.dispose();
              totalMarksCtrl.dispose();
              Navigator.pop(context);
            },
            child: Text(t(L.cancel, ref)),
          ),
          ElevatedButton(
            onPressed: () async {
              final examName = examNameCtrl.text;
              final subject = subjectCtrl.text;
              final className = classNameCtrl.text;
              final studentName = studentNameCtrl.text;
              final score = double.tryParse(scoreCtrl.text) ?? 0;
              final totalMarks = double.tryParse(totalMarksCtrl.text) ?? 100;
              final percentage = totalMarks > 0 ? (score / totalMarks) * 100 : 0.0;
              examNameCtrl.dispose();
              subjectCtrl.dispose();
              classNameCtrl.dispose();
              studentNameCtrl.dispose();
              scoreCtrl.dispose();
              totalMarksCtrl.dispose();
              Navigator.pop(context);
              if (examName.isEmpty || subject.isEmpty || studentName.isEmpty) return;
              try {
                await Supabase.instance.client.from('exam_results').insert({
                  'exam_name': examName,
                  'subject': subject,
                  'class': className,
                  'student_name': studentName,
                  'score': score,
                  'total_marks': totalMarks,
                  'percentage': percentage,
                  'exam_date': DateTime.now().toIso8601String(),
                  'created_at': DateTime.now().toIso8601String(),
                  'updated_at': DateTime.now().toIso8601String(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(t(LAll.all_results_added_successfully, ref))),
                  );
                  ref.invalidate(examResultsStreamProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tt(LAll.all_failed_to_add_results_x, ref, [e.toString()]))),
                  );
                }
              }
            },
            child: Text(t(L.add, ref)),
          ),
        ],
      ),
    );
  }
}

