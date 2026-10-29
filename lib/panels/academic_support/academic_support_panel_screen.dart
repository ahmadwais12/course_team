import 'package:flutter/material.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/panel_widgets.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class AcademicSupportPanelScreen extends ConsumerWidget {
  const AcademicSupportPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academicStatsAsync = ref.watch(academicSupportStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.academicSupportPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'academic-dashboard',
          tables: ['students', 'classes', 'attendance', 'exams'],
          onChange: () => ref.invalidate(academicSupportStatsProvider),
        ),

        academicStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'STUDENT LIFECYCLE',
                  title: 'Academic Support Command Center',
                  subtitle:
                      'Manage admissions, student profiles, attendance, results, course structure, and academic follow-up from one place.',
                  accent: Colors.indigo,
                  chips: [
                    InsightStatChip(
                      label: t(LNav.students, ref),
                      value: stats.totalStudents.toString(),
                    ),
                    InsightStatChip(
                      label: t(LNav.classes, ref),
                      value: stats.totalClasses.toString(),
                    ),
                    InsightStatChip(
                      label: t(LNav.programs, ref),
                      value: stats.totalPrograms.toString(),
                    ),
                    InsightStatChip(
                      label: t(LNav.exams, ref),
                      value: stats.scheduledExams.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () =>
                          context.go(AppRoutes.studentRegistration),
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Register Student',
                      gradient: AppGradients.skyCyanHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.reports),
                      icon: Icons.assessment_rounded,
                      label: 'Academic Reports',
                      gradient: AppGradients.blueHorizontal,
                      isOutlined: true,
                    ),
                  ],
                );
              },
              loading: () => const PageSkeleton(type: 'dashboard'),
              error: (_, __) => const SizedBox.shrink(),
            )
            .animate()
            .fadeIn(duration: 700.ms)
            .scale(begin: const Offset(0.96, 0.96), end: const Offset(1, 1)),
        const SizedBox(height: 24),
        InsightSectionTitle(
          title: 'Academic Workflow',
          subtitle:
              'Core academic support responsibilities from onboarding to completion',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.deepPurple,
          steps: const [
            InsightFlowStep(
              title: 'Register',
              subtitle: 'Enroll student',
              icon: Icons.app_registration_rounded,
            ),
            InsightFlowStep(
              title: 'Assign',
              subtitle: 'Course, level, class',
              icon: Icons.fact_check_rounded,
            ),
            InsightFlowStep(
              title: 'Track',
              subtitle: 'Attendance & results',
              icon: Icons.track_changes_rounded,
            ),
            InsightFlowStep(
              title: 'Complete',
              subtitle: 'Reports & certificates',
              icon: Icons.workspace_premium_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),
        InsightSectionTitle(
          title: 'Academic Support Modules',
          subtitle: 'Mapped from your final panel structure',
        ),
        const SizedBox(height: 12),
        PanelActionGrid(
          actions: [
            (
              'Student Registration',
              Icons.person_add_alt_1_rounded,
              Colors.blue,
              () => context.go(AppRoutes.studentRegistration)
            ),
            (
              'Student Accounts',
              Icons.manage_accounts_rounded,
              Colors.indigo,
              () => context.go(AppRoutes.students)
            ),
            (
              'Student Profiles',
              Icons.badge_rounded,
              Colors.teal,
              () => context.go(AppRoutes.students)
            ),
            (
              'Classes & Batches',
              Icons.groups_rounded,
              Colors.orange,
              () => context.go(AppRoutes.classes)
            ),
            (
              'Attendance',
              Icons.how_to_reg_rounded,
              Colors.blue,
              () => context.go(AppRoutes.attendance)
            ),
            (
              'Grades & Results',
              Icons.grade_rounded,
              Colors.purple,
              () => context.go(AppRoutes.grades)
            ),
            (
              'Exams',
              Icons.quiz_rounded,
              Colors.red,
              () => context.go(AppRoutes.exams)
            ),
            (
              'Course Levels',
              Icons.menu_book_rounded,
              Colors.cyan,
              () => context.go(AppRoutes.programs)
            ),
            (
              'Books & Materials',
              Icons.library_books_rounded,
              Colors.brown,
              () => context.go(AppRoutes.books)
            ),
            (
              'Placement Tests',
              Icons.rule_folder_rounded,
              Colors.deepPurple,
              () => context.go(AppRoutes.englishTest)
            ),
            (
              'Course Feedback',
              Icons.feedback_rounded,
              Colors.pink,
              () => context.go(AppRoutes.feedback)
            ),
            (
              'Certificates',
              Icons.workspace_premium_rounded,
              Colors.amber,
              () => context.go(AppRoutes.certificateGeneration)
            ),
            (
              'Reports & History',
              Icons.timeline_rounded,
              Colors.lime,
              () => context.go(AppRoutes.reports)
            ),
          ],
        ).animate().fadeIn(delay: 250.ms, duration: 550.ms),
        const SizedBox(height: 24),
        academicStatsAsync
            .when(
              data: (stats) {
                return ResponsiveMetricRow(
                  children: [
                    InsightMetricCard(
                      label: 'Active Students',
                      value: stats.activeStudents.toString(),
                      trend: 'Current status',
                      icon: Icons.people_alt_rounded,
                      accent: Colors.blue,
                    ),
                    InsightMetricCard(
                      label: 'Attendance Logs',
                      value: stats.attendanceRecords.toString(),
                      trend: 'Tracked records',
                      icon: Icons.fact_check_rounded,
                      accent: Colors.blue,
                    ),
                    InsightMetricCard(
                      label: 'Placement Tests',
                      value: stats.placementTests.toString(),
                      trend: 'Assessment queue',
                      icon: Icons.assignment_turned_in_rounded,
                      accent: Colors.deepPurple,
                    ),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
            .animate()
            .fadeIn(delay: 350.ms, duration: 500.ms),
        const SizedBox(height: 24),
        InsightSectionTitle(
          title: 'Coverage Matrix',
          subtitle: 'How this panel is organized around the academic workflow',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Outcome'],
          rows: [
            [
              'Onboarding',
              'Registration, IDs, documents',
              'Admissions',
              'Student enrolled'
            ],
            [
              'Academic Ops',
              'Classes, attendance, grades',
              'Students & classes',
              'Progress tracked'
            ],
            [
              'Courses',
              'Programs, levels, materials',
              'Programs & books',
              'Learning mapped'
            ],
            [
              'Support',
              'Feedback, complaints, reports',
              'Feedback & reports',
              'Issues resolved'
            ],
          ],
        ),
        const SizedBox(height: 24),
        FutureBuilder(
          future: supabase
              .from('students')
              .select('full_name, status, program, created_at')
              .order('created_at', ascending: false)
              .limit(4),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PageSkeleton(type: 'list', itemCount: 4);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final students = snapshot.data as List;
            final rows = students.map((student) {
              return [
                student['full_name']?.toString() ?? 'Student',
                student['program']?.toString() ?? 'Unassigned',
                student['status']?.toString() ?? 'Active',
                _formatDate(student['created_at']?.toString()),
              ];
            }).toList();

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest registrations and onboarding flow',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.students),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Student', 'Program', 'Status', 'Added'],
                  rows: rows.isEmpty
                      ? [
                          [t(L.noData, ref), '-', '-', '-'],
                        ]
                      : rows,
                ),
              ],
            );
          },
        ).animate().fadeIn(delay: 550.ms, duration: 500.ms),
      ],
    );
  }

  static String _formatDate(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return '-';
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isOutlined;

  const _GradientButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradient,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isOutlined) {
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        padding: const EdgeInsets.all(2),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
