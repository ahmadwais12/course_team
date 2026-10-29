import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';
import '../widgets/modern_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AIInsightsScreen extends ConsumerStatefulWidget {
  final String studentId;

  const AIInsightsScreen({super.key, required this.studentId});

  @override
  ConsumerState<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends ConsumerState<AIInsightsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _grades;
  List<Map<String, dynamic>> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AIService.instance.predictAttendance(widget.studentId),
        AIService.instance.analyzeGrades(widget.studentId),
        AIService.instance.getPerformanceInsights(widget.studentId),
      ]);
      
      setState(() {
        _attendance = results[0] as Map<String, dynamic>;
        _grades = results[1] as Map<String, dynamic>;
        _insights = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.aiInsights, ref))),
      body: _loading
          ? const PageSkeleton(type: 'dashboard')
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t(LDash2.attendanceRate, ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildStatRow('Rate', '${_attendance?['attendance_rate']?.toStringAsFixed(1)}%'),
                        _buildStatRow('Prediction', _attendance?['prediction'] ?? 'N/A'),
                        _buildStatRow('Risk Level', _attendance?['risk_level'] ?? 'N/A'),
                        Text(_attendance?['recommendation'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ModernCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t(LAnalyticsPS.analytics, ref), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildStatRow('Average', _grades?['average'] ?? 'N/A'),
                        _buildStatRow('Trend', _grades?['trend'] ?? 'N/A'),
                        _buildStatRow('Grade', _grades?['grade'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Performance Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._insights.map((insight) => ModernCard(
                        child: ListTile(
                          leading: Icon(
                            insight['type'] == 'warning' ? Icons.warning : Icons.check_circle,
                            color: insight['type'] == 'warning' ? Colors.orange : Colors.blue,
                          ),
                          title: Text(insight['title']),
                          subtitle: Text(insight['message']),
                        ),
                      )),
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.blue)),
        ],
      ),
    );
  }
}
