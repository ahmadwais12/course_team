import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class StudentProgressScreen extends ConsumerStatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  ConsumerState<StudentProgressScreen> createState() =>
      _StudentProgressScreenState();
}

class _StudentProgressScreenState extends ConsumerState<StudentProgressScreen> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(studentProgressProvider);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Student Progress')),
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
            child: progressAsync.when(
              data: (progressList) {
                var filtered = progressList.where((p) {
                  final student =
                      p['student_name']?.toString().toLowerCase() ?? '';
                  final subject =
                      p['subject']?.toString().toLowerCase() ?? '';
                  final searchLower = searchQuery.toLowerCase();
                  return student.contains(searchLower) ||
                      subject.contains(searchLower);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_up_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No progress data found',
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
                    final student = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getGradeColor(student['average_score']),
                          child: Text(
                              '${(student['average_score'] ?? 0).toInt()}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                        ),
                        title: Text(
                            student['student_name']?.toString() ?? 'Unknown'),
                        subtitle: Text(
                            '${student['class']} • ${student['subject']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              student['trend'] == 'up'
                                  ? Icons.trending_up
                                  : student['trend'] == 'down'
                                      ? Icons.trending_down
                                      : Icons.remove,
                              color: _getTrendColor(student['trend']),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () =>
                                  _showProgressDetails(student),
                            ),
                          ],
                        ),
                        onTap: () => _showProgressDetails(student),
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
                    Icon(Icons.error_outline,
                        size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(studentProgressProvider),
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
    );
  }

  Color _getGradeColor(dynamic grade) {
    final g = (grade is num) ? grade.toDouble() : 0.0;
    if (g >= 85) return Colors.blue;
    if (g >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getTrendColor(dynamic trend) {
    switch (trend?.toString().toLowerCase() ?? '') {
      case 'up':
        return Colors.blue;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showProgressDetails(Map<String, dynamic> student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student['student_name']?.toString() ?? 'Unknown',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildStatCard('Overall Average',
                  '${(student['average_score'] ?? 0).toStringAsFixed(1)}%',
                  Icons.analytics),
              const SizedBox(height: 12),
              _buildStatCard(
                  'Class', student['class']?.toString() ?? '', Icons.school),
              const SizedBox(height: 12),
              _buildStatCard(
                  'Trend',
                  student['trend']?.toString().toUpperCase() ?? '',
                  Icons.trending_up),
              const SizedBox(height: 24),
              const Text('Subject Breakdown:',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildSubjectRow('Overall Progress',
                  (student['overall_progress'] ?? 0).toInt()),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Report generated successfully')),
                  );
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Generate Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600])),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectRow(String subject, int score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(subject)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getGradeColor(score.toDouble()).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$score%',
                style: TextStyle(
                    color: _getGradeColor(score.toDouble()),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}


