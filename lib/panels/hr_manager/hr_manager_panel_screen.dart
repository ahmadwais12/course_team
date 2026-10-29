import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/nav.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';


class HRManagerPanelScreen extends ConsumerWidget {
  const HRManagerPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hrStatsAsync = ref.watch(hrStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.hrManagerPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'hr-dashboard',
          tables: ['employee_leaves', 'job_applications', 'staff_attendance'],
          onChange: () => ref.invalidate(hrStatsProvider),
        ),

        // Hero Card - Critical Rule: ONLY Staff
        hrStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'HUMAN RESOURCES & OPERATIONS',
                  title: 'HR Command Center',      subtitle: 'Staff recruitment, contracts, payroll, attendance, leave management, performance reviews, and compliance. ${supabase.auth.currentUser?.email ?? ''}',
                  accent: Colors.orange,
                  chips: [
                    InsightStatChip(
                      label: 'Total Staff',
                      value: stats.totalStaff.toString(),
                    ),
                    InsightStatChip(
                      label: 'Active Today',
                      value: stats.activeToday.toString(),
                    ),
                    InsightStatChip(
                      label: 'On Leave',
                      value: stats.onLeave.toString(),
                    ),
                    InsightStatChip(
                      label: 'Openings',
                      value: stats.totalOpenings.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.recruitment),
                      icon: Icons.person_add_rounded,
                      label: 'New Hire',
                      gradient: AppGradients.orangeAmberHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.payroll),
                      icon: Icons.payments_rounded,
                      label: 'Process Payroll',
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
            .fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
        const SizedBox(height: 24),

        // HR Workflow
        InsightSectionTitle(
          title: 'HR Workflow',
          subtitle:
              'Complete employee lifecycle management from recruitment to exit',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.orange,
          steps: const [
            InsightFlowStep(
              title: 'Recruit',
              subtitle: 'Post & Screen',
              icon: Icons.person_search_rounded,
            ),
            InsightFlowStep(
              title: 'Onboard',
              subtitle: 'Hire & Contract',
              icon: Icons.person_add_rounded,
            ),
            InsightFlowStep(
              title: 'Manage',
              subtitle: 'Attendance & Leave',
              icon: Icons.manage_accounts_rounded,
            ),
            InsightFlowStep(
              title: 'Pay',
              subtitle: 'Payroll & Benefits',
              icon: Icons.payments_rounded,
            ),
            InsightFlowStep(
              title: 'Develop',
              subtitle: 'Train & Review',
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // HR Modules Grid
        InsightSectionTitle(
          title: 'HR & Operations Modules',
          subtitle: 'Comprehensive tools for staff management only',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        hrStatsAsync
            .when(
              data: (stats) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 600;
                    final items = [
                      InsightMetricCard(
                        label: 'Attendance Rate',
                        value:
                            '${((stats.activeToday / (stats.totalStaff > 0 ? stats.totalStaff : 1)) * 100).toStringAsFixed(0)}%',
                        trend: 'Today',
                        icon: Icons.check_circle_rounded,
                        accent: Colors.blue,
                      ),
                      InsightMetricCard(
                        label: 'Pending Leaves',
                        value: stats.onLeave.toString(),
                        trend: 'Approved',
                        icon: Icons.beach_access_rounded,
                        accent: Colors.orange,
                      ),
                      InsightMetricCard(
                        label: 'New Hires (30d)',
                        value: '4',
                        trend: 'This month',
                        icon: Icons.person_add_rounded,
                        accent: Colors.blue,
                      ),
                      InsightMetricCard(
                        label: 'Compliance Score',
                        value: '98%',
                        trend: 'On Track',
                        icon: Icons.verified_rounded,
                        accent: Colors.purple,
                      ),
                    ];

                    if (isCompact) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: items[0]),
                              const SizedBox(width: 12),
                              Expanded(child: items[1]),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: items[2]),
                              const SizedBox(width: 12),
                              Expanded(child: items[3]),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: items[0]),
                        const SizedBox(width: 12),
                        Expanded(child: items[1]),
                        const SizedBox(width: 12),
                        Expanded(child: items[2]),
                        const SizedBox(width: 12),
                        Expanded(child: items[3]),
                      ],
                    );
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            )
            .animate()
            .fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Panel Responsibility Matrix - Critical Rule Highlight
        InsightSectionTitle(
          title: 'Panel Responsibility Matrix',
          subtitle: 'HR & Operations manages ONLY staff - NEVER students',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Manages', 'Never Accesses', 'Key Function'],
          rows: [
            [
              'Staff Records',
              'All staff data',
              'Student Records',
              'Employment Management'
            ],
            [
              'Recruitment',
              'Job postings, applications',
              'Student Admissions',
              'Talent Acquisition'
            ],
            ['Payroll', 'Salaries, bonuses', 'Student Fees', 'Compensation'],
            [
              'Attendance',
              'Staff clock-in/out',
              'Student Attendance',
              'Time Tracking'
            ],
            [
              'Contracts',
              'Employment agreements',
              'Enrollment Contracts',
              'Legal Compliance'
            ],
            [
              'Performance',
              'Staff reviews, KPIs',
              'Student Grades',
              'Talent Development'
            ],
            [
              'Training',
              'Staff development',
              'Student Curriculum',
              'Skill Building'
            ],
            [
              'Benefits',
              'Insurance, perks',
              'Scholarships',
              'Employee Welfare'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent HR Requests from Database
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('employee_leaves')
                .select('*, users(full_name)')
                .eq('status', 'pending')
                .order('created_at', ascending: false)
                .limit(3),
            supabase
                .from('job_applications')
                .select()
                .eq('status', 'Applied')
                .order('applied_date', ascending: false)
                .limit(2),
          ]),
          builder: (context, AsyncSnapshot<List<Object?>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PageSkeleton(type: 'list', itemCount: 5);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final leaves = snapshot.data![0] as List;
            final applications = snapshot.data![1] as List;
            final List<List<String>> rows = [];

            for (var leave in leaves) {
              rows.add([
                'Leave: ${leave['users']?['full_name'] ?? 'Employee'}',
                leave['leave_category']?.toString() ?? 'Leave',
                '${_calculateDays(leave['start_date'], leave['end_date'])} days',
                _timeAgo(leave['created_at']),
                'Pending',
              ]);
            }

            for (var app in applications) {
              rows.add([
                'Application: ${app['applicant_name'] ?? 'Candidate'}',
                'Job Application',
                app['position']?.toString() ?? 'General',
                _timeAgo(app['applied_date']),
                'New',
              ]);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Pending leave requests and new applications',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.reports),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const [
                    'Request',
                    'Type',
                    'Details',
                    'Submitted',
                    'Status'
                  ],
                  rows: rows.isEmpty
                      ? [
                          [t(L.noData, ref), '-', '-', '-', '-'],
                        ]
                      : rows,
                ),
              ],
            );
          },
        ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildModulesGrid(BuildContext context) {
    final isMobile = context.isMobile;
    final crossAxisCount = isMobile ? 2 : 3;
    final modules = [
      (
        'Staff Directory',
        Icons.contacts_rounded,
        Colors.blue,
        AppRoutes.staffDirectory,
        'Manage all employee records',
      ),
      (
        'Recruitment',
        Icons.person_search_rounded,
        Colors.blue,
        AppRoutes.recruitment,
        'Job postings and applications',
      ),
      (
        'Staff Attendance',
        Icons.fingerprint_rounded,
        Colors.orange,
        AppRoutes.staffAttendance,
        'Clock-in/out and tracking',
      ),
      (
        'Leave Management',
        Icons.beach_access_rounded,
        Colors.purple,
        AppRoutes.leaveManagement,
        'Approve and track leaves',
      ),
      (
        'Payroll Hub',
        Icons.payments_rounded,
        Colors.teal,
        AppRoutes.payroll,
        'Process salaries and bonuses',
      ),
      (
        'Contracts',
        Icons.description_rounded,
        Colors.indigo,
        AppRoutes.contracts,
        'Employment agreements',
      ),
      (
        'Performance',
        Icons.trending_up_rounded,
        Colors.pink,
        AppRoutes.performance,
        'Reviews and KPIs',
      ),
      (
        'Training',
        Icons.school_rounded,
        Colors.red,
        AppRoutes.training,
        'Staff development programs',
      ),
      (
        'Onboarding',
        Icons.person_add_rounded,
        Colors.cyan,
        AppRoutes.onboardingStaff,
        'New hire orientation',
      ),
      (
        'Benefits',
        Icons.health_and_safety_rounded,
        Colors.amber,
        AppRoutes.benefits,
        'Insurance and perks',
      ),
      (
        'Compliance',
        Icons.verified_user_rounded,
        Colors.deepPurple,
        AppRoutes.compliance,
        'Labor law adherence',
      ),
      (
        'Exit Management',
        Icons.exit_to_app_rounded,
        Colors.brown,
        AppRoutes.exitManagement,
        'Offboarding process',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isMobile ? 1.2 : 1.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final module = modules[index];
        return _buildModuleCard(
          context,
          module.$1,
          module.$2,
          module.$3,
          module.$4,
          module.$5,
        )
            .animate()
            .fadeIn(delay: (index * 50).ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      },
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String route,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(dynamic date) {
    if (date == null) return 'Recently';
    try {
      final dt = DateTime.parse(date.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Recently';
    }
  }

  String _calculateDays(dynamic startDate, dynamic endDate) {
    try {
      if (startDate == null || endDate == null) return '1';
      final start = DateTime.parse(startDate.toString());
      final end = DateTime.parse(endDate.toString());
      return '${end.difference(start).inDays + 1}';
    } catch (e) {
      return '1';
    }
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
