import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/teacher_providers.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class StudentProgressScreenRealtime extends ConsumerStatefulWidget {
  const StudentProgressScreenRealtime({super.key});

  @override
  ConsumerState<StudentProgressScreenRealtime> createState() =>
      _StudentProgressScreenRealtimeState();
}

class _StudentProgressScreenRealtimeState
    extends ConsumerState<StudentProgressScreenRealtime> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(studentProgressStreamProvider);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()), title: const Text('Student Progress')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search students...',
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
                  final subject = p['subject']?.toString().toLowerCase() ?? '';
                  return student.contains(searchQuery.toLowerCase()) ||
                      subject.contains(searchQuery.toLowerCase());
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
                    final progress = filtered[index];
                    final overallProgress = progress['overall_progress'] ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _showDetails(progress),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        _getProgressColor(overallProgress)
                                            .withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: _getProgressColor(overallProgress),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          progress['student_name']
                                                  ?.toString() ??
                                              'Unknown',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                            '${progress['class']} • ${progress['subject']}'),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getTrendColor(progress['trend'])
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          progress['trend'] == 'up'
                                              ? Icons.trending_up
                                              : progress['trend'] == 'down'
                                                  ? Icons.trending_down
                                                  : Icons.trending_flat,
                                          size: 16,
                                          color:
                                              _getTrendColor(progress['trend']),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${overallProgress.toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            color: _getTrendColor(
                                                progress['trend']),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Text('Overall Progress:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  Text(
                                      '${overallProgress.toStringAsFixed(0)}%'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: overallProgress / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(overallProgress)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildStatChip('Tests',
                                      progress['tests_completed'] ?? 0),
                                  const SizedBox(width: 8),
                                  _buildStatChip('Avg Score',
                                      '${(progress['average_score'] ?? 0.0).toStringAsFixed(1)}%'),
                                  const SizedBox(width: 8),
                                  _buildStatChip('Assignments',
                                      progress['assignments_pending'] ?? 0),
                                ],
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
                    Text('Error: $error'),
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.invalidate(studentProgressStreamProvider),
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

  Color _getProgressColor(double progress) {
    if (progress < 50) return Colors.orange;
    if (progress < 75) return Colors.blue;
    return Colors.blue;
  }

  Color _getTrendColor(dynamic trend) {
    switch (trend.toString().toLowerCase()) {
      case 'up':
        return Colors.blue;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatChip(String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value.toString(),
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showDetails(Map<String, dynamic> progress) {
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
                progress['student_name']?.toString() ?? 'Unknown',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Class', progress['class']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  'Subject', progress['subject']?.toString() ?? 'N/A'),
              _buildDetailRow(
                  'Overall Progress', '${progress['overall_progress']}%'),
              _buildDetailRow('Average Score', '${progress['average_score']}%'),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('View detailed progress report')),
                  );
                },
                icon: const Icon(Icons.analytics),
                label: const Text('Detailed Report'),
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

