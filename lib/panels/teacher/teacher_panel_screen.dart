import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/panel_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:course_emis/widgets/motion_ui.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/services/dashboard_service.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
import 'package:course_emis/l10n/locale_keys.dart';

final _teacherMetricsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  return DashboardService.instance.fetchTeacherMetrics(userId);
});

class TeacherPanelScreen extends ConsumerWidget {
  const TeacherPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherStatsAsync = ref.watch(teacherStatsProvider);
    final metricsAsync = ref.watch(_teacherMetricsProvider);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    return BasePanelLayout(
      title: t(LPanel.teacherPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'teacher-dashboard',
          tables: ['lesson_plans', 'attendance'],
          onChange: () => ref.invalidate(_teacherMetricsProvider),
        ),

        // Stats from DB
        PanelSectionTitle(title: t(LNav.dashboard, ref)),
        teacherStatsAsync.when(
          data: (stats) {
            final rate = metricsAsync.valueOrNull?['attendanceRate'] ?? 0;
            return TiltCard(
              child: PanelStatGrid(stats: [
                (t(LModule.lessonPlans, ref), stats.totalLessonPlans.toString(), Icons.menu_book_rounded, Colors.blue, 'Created'),
                (t(LModule.homework, ref), stats.totalHomework.toString(), Icons.assignment_rounded, Colors.blue, 'Active'),
                (t(LModule.studentGroups, ref), stats.totalGroups.toString(), Icons.groups_rounded, Colors.orange, 'Managed'),
                (t(LNav.attendance, ref), '$rate%', Icons.check_circle_rounded, Colors.purple, 'Avg'),
              ]),
            );
          },
          loading: () => const PageSkeleton(type: 'dashboard'),
          error: (_, __) => TiltCard(
            child: PanelStatGrid(stats: [
              (t(LModule.lessonPlans, ref), '0', Icons.menu_book_rounded, Colors.blue, 'Created'),
              (t(LModule.homework, ref), '0', Icons.assignment_rounded, Colors.blue, 'Active'),
              (t(LModule.studentGroups, ref), '0', Icons.groups_rounded, Colors.orange, 'Managed'),
              (t(LNav.attendance, ref), '0%', Icons.check_circle_rounded, Colors.purple, 'Avg'),
            ]),
          ),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),

        PanelSectionTitle(title: t(LUX.quickAccess, ref)),
        PanelActionGrid(actions: [
          (t(LModule.mySchedule, ref), Icons.calendar_today_rounded, Colors.blue, () => context.go('/my-schedule')),
          ('My Students', Icons.people_rounded, Colors.blue, () => context.go('/my-students')),
          (t(LNav.grades, ref), Icons.grade_rounded, Colors.orange, () => context.go('/grades')),
          (t(LModule.lessonPlans, ref), Icons.menu_book_rounded, Colors.purple, () => context.go('/lesson-plans')),
          (t(LModule.messageParents, ref), Icons.message_rounded, Colors.red, () => context.go('/message-parents')),
          (t(LExam.examResults, ref), Icons.assessment_rounded, Colors.teal, () => context.go('/exam-results')),
          (t(LModule.studentGroups, ref), Icons.group_work_rounded, Colors.cyan, () => context.go('/student-groups')),
          (t(LModule.studentProgress, ref), Icons.trending_up_rounded, Colors.indigo, () => context.go('/student-progress')),
        ]).animate().fadeIn(delay: 200.ms, duration: 600.ms),

        const SizedBox(height: 24),

        // Schedule from DB
        PanelSectionTitle(title: t(LTime.classSchedule, ref)),
        FutureBuilder(
          future: DashboardService.instance.fetchTeacherSchedule(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const PageSkeleton(type: 'list', itemCount: 3);
            final schedules = snapshot.data ?? [];
            if (schedules.isEmpty) return _buildDefaultClasses(context);
            return Column(
              children: schedules.map((schedule) {
                final cls = schedule['classes'] as Map<String, dynamic>?;
                final name = cls?['name'] as String? ?? 'Class';
                final location = schedule['location'] as String? ?? 'TBD';
                final time = schedule['start_time'] as String? ?? '';
                return _buildClassItem(context, name, location, _formatTime(time), Colors.blue, Icons.class_rounded)
                    .animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0);
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 24),

        // Quick stats from real data
        metricsAsync.when(
          data: (m) => ResponsiveMetricRow(children: [
            _buildMiniStat('Present Today', '${m['presentToday'] ?? 0}', Colors.green, Icons.check_circle_rounded),
            _buildMiniStat('Total Today', '${m['totalToday'] ?? 0}', Colors.blue, Icons.people_rounded),
            _buildMiniStat('Homework', '${m['totalHomework'] ?? 0}', Colors.orange, Icons.assignment_rounded),
          ]),
          loading: () => ResponsiveMetricRow(children: [
            _buildMiniStat('Present Today', '...', Colors.green, Icons.check_circle_rounded),
            _buildMiniStat('Total Today', '...', Colors.blue, Icons.people_rounded),
            _buildMiniStat('Homework', '...', Colors.orange, Icons.assignment_rounded),
          ]),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ]),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildClassItem(BuildContext context, String title, String subtitle, String time, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('$subtitle • $time', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => context.go('/my-schedule'),
      ),
    );
  }

  Widget _buildDefaultClasses(BuildContext context) {
    return Column(children: [
      _buildClassItem(context, 'Mathematics 101', 'Grade 10-A • Room 302', '09:00 AM', Colors.blue, Icons.calculate_rounded).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
      _buildClassItem(context, 'Physics Lab', 'Grade 11-B • Lab 2', '11:30 AM', Colors.orange, Icons.science_rounded).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),
    ]);
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'TBD';
    try {
      if (time is String) {
        final parts = time.split(':');
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        return '$displayHour:$minute $period';
      }
      return time.toString();
    } catch (e) {
      return 'TBD';
    }
  }
}

