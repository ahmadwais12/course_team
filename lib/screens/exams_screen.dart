import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class ExamsScreen extends ConsumerStatefulWidget {
  const ExamsScreen({super.key});

  @override
  ConsumerState<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends ConsumerState<ExamsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LNav.exams, ref)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: t(LTime.thisMonth, ref)),
            Tab(text: t(LExam.examResults, ref)),
            Tab(text: t(LExam.certificate, ref)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateExamDialog(context),
        child: const Icon(Icons.add),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: TabBarView(
            controller: _tabController,
            children: const [
              _UpcomingExams(),
              _ExamResults(),
              _Certificates(),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateExamDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _CreateExamPage(),
        fullscreenDialog: true,
      ),
    );
  }
}

class _CreateExamPage extends ConsumerStatefulWidget {
  const _CreateExamPage();

  @override
  ConsumerState<_CreateExamPage> createState() => _CreateExamPageState();
}

class _CreateExamPageState extends ConsumerState<_CreateExamPage> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LCrud.addExamResult, ref)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t(L.cancel, ref))),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(decoration: InputDecoration(labelText: t(LCourse.schedule, ref))),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Course')),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Date')),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Duration (minutes)')),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(labelText: 'Total Marks')),
          const SizedBox(height: 24),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t(L.add, ref))),
        ],
      ),
    );
  }
}

class _UpcomingExams extends ConsumerStatefulWidget {
  const _UpcomingExams();

  @override
  ConsumerState<_UpcomingExams> createState() => _UpcomingExamsState();
}

class _UpcomingExamsState extends ConsumerState<_UpcomingExams> {
  List<Map<String, dynamic>> _exams = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('exams')
          .select()
          .order('date', ascending: true);
      if (mounted) setState(() => _exams = data);
    } catch (e) {
      if (mounted) setState(() => _exams = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ExamsSkeleton();

    if (_exams.isEmpty) {
      return ListView(
        padding: AppSpacing.paddingLg,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(t(LAll.all_no_upcoming_exams, ref),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: AppSpacing.paddingLg,
      children: _exams.map((exam) {
        final examColors = [Colors.orange, Colors.blue, Colors.purple, Colors.teal, Colors.red];
        final color = examColors[_exams.indexOf(exam) % examColors.length];
        return _ExamCard(
          title: exam['title']?.toString() ?? 'Untitled',
          date: _formatDate(exam['date']?.toString()),
          time: exam['time']?.toString() ?? '',
          duration: exam['duration']?.toString() ?? '',
          totalMarks: (exam['total_marks'] ?? 0).toDouble(),
          status: exam['status']?.toString() ?? 'Upcoming',
          color: color,
        );
      }).toList(),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.length < 10) return date ?? '';
    return date.substring(0, 10);
  }
}

class _ExamResults extends ConsumerStatefulWidget {
  const _ExamResults();

  @override
  ConsumerState<_ExamResults> createState() => _ExamResultsState();
}

class _ExamResultsState extends ConsumerState<_ExamResults> {
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('exam_results')
          .select()
          .order('date', ascending: false);
      if (mounted) setState(() => _results = data);
    } catch (e) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_results.isEmpty) {
      return ListView(
        padding: AppSpacing.paddingLg,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(t(LAll.all_no_exam_results_yet, ref),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: AppSpacing.paddingLg,
      children: _results.map((r) => _ResultCard(
        examTitle: r['exam_title']?.toString() ?? 'Untitled',
        date: _formatDate(r['date']?.toString()),
        marksObtained: r['marks_obtained'] ?? 0,
        totalMarks: r['total_marks'] ?? 0,
        grade: r['grade']?.toString() ?? '-',
        percentage: (r['percentage'] ?? 0.0).toDouble(),
      )).toList(),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.length < 10) return date ?? '';
    return date.substring(0, 10);
  }
}

class _Certificates extends ConsumerStatefulWidget {
  const _Certificates();

  @override
  ConsumerState<_Certificates> createState() => _CertificatesState();
}

class _CertificatesState extends ConsumerState<_Certificates> {
  List<Map<String, dynamic>> _certificates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('certificates')
          .select()
          .order('issue_date', ascending: false);
      if (mounted) setState(() => _certificates = data);
    } catch (e) {
      if (mounted) setState(() => _certificates = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_certificates.isEmpty) {
      return ListView(
        padding: AppSpacing.paddingLg,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(t(LAll.all_no_certificates_yet, ref),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: AppSpacing.paddingLg,
      children: _certificates.map((c) => _CertificateCard(
        title: c['title']?.toString() ?? 'Untitled',
        issueDate: _formatDate(c['issue_date']?.toString()),
        certificateNo: c['certificate_no']?.toString() ?? '-',
        grade: c['grade']?.toString() ?? '-',
      )).toList(),
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.length < 7) return date ?? '';
    return date.length >= 10 ? date.substring(0, 10) : date;
  }
}

class _ExamCard extends ConsumerWidget {
  final String title;
  final String date;
  final String time;
  final String duration;
  final double totalMarks;
  final String status;
  final Color color;

  const _ExamCard({
    required this.title,
    required this.date,
    required this.time,
    required this.duration,
    required this.totalMarks,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
                Chip(
                  label: Text(status, style: const TextStyle(fontSize: 10)),
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: AppSpacing.sm),
                    Text(date, style: theme.textTheme.bodySmall),
                    const SizedBox(width: AppSpacing.md),
                    Icon(Icons.access_time,
                        size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: AppSpacing.sm),
                    Text(time, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.timer,
                        size: 16, color: theme.textTheme.bodySmall?.color),
                    const SizedBox(width: AppSpacing.sm),
                    Text(tt(LAll.all_duration_x, ref, [duration]),
                        style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(tt(LAll.all_total_x_marks, ref, [totalMarks.toString()]),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends ConsumerWidget {
  final String examTitle;
  final String date;
  final int marksObtained;
  final int totalMarks;
  final String grade;
  final double percentage;

  const _ResultCard({
    required this.examTitle,
    required this.date,
    required this.marksObtained,
    required this.totalMarks,
    required this.grade,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = percentage >= 90
        ? Colors.blue
        : percentage >= 75
            ? Colors.blue
            : Colors.orange;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(examTitle,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(grade,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(LAll.all_marks, ref), style: theme.textTheme.labelSmall),
                    Text(tt(LAll.all_s456, ref, [marksObtained.toString(), totalMarks.toString()]),
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(LExam.percentage, ref), style: theme.textTheme.labelSmall),
                    Text(tt(LAll.all_s3, ref, [percentage.toStringAsFixed(1)]),
                        style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends ConsumerWidget {
  final String title;
  final String issueDate;
  final String certificateNo;
  final String grade;

  const _CertificateCard({
    required this.title,
    required this.issueDate,
    required this.certificateNo,
    required this.grade,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.white, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(tt(LAll.all_issued_x, ref, [issueDate]),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t(LAll.all_certificate_no, ref),
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(certificateNo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(t(LExam.grade, ref),
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
                      Text(grade,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/reports'),
                icon: const Icon(Icons.download, color: Colors.white),
                label: Text(t(LAll.all_download_pdf, ref),
                    style: const TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


