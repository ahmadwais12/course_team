import 'package:flutter/material.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class ComplaintManagerPanelScreen extends ConsumerWidget {
  const ComplaintManagerPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintManagerStatsAsync = ref.watch(complaintManagerStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.complaintManagerPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'complaint-dashboard',
          tables: ['complaints', 'complaint_messages', 'feedback'],
          onChange: () => ref.invalidate(complaintManagerStatsProvider),
        ),

        // Hero Card
        complaintManagerStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'COMPLAINT RESOLUTION',
                  title: 'Complaint Resolution Center',
                  subtitle:
                      'Receive, investigate, and resolve complaints with priority tracking, case timelines, and customer feedback.',
                  accent: Colors.red,
                  chips: [
                    InsightStatChip(
                      label: 'Total Cases',
                      value: stats.totalComplaints.toString(),
                    ),
                    InsightStatChip(
                      label: 'Pending',
                      value: stats.pendingComplaints.toString(),
                    ),
                    InsightStatChip(
                      label: 'Resolved',
                      value: stats.resolvedComplaints.toString(),
                    ),
                    InsightStatChip(
                      label: 'Escalated',
                      value: (stats.totalComplaints -
                              stats.pendingComplaints -
                              stats.resolvedComplaints)
                          .clamp(0, stats.totalComplaints)
                          .toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.complaintDetails),
                      icon: Icons.assignment_late_rounded,
                      label: 'New Complaint',
                      gradient: AppGradients.orangeAmberHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.resolved),
                      icon: Icons.checklist_rounded,
                      label: 'Resolved Cases',
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

        // Resolution Workflow
        InsightSectionTitle(
          title: 'Resolution Workflow',
          subtitle: 'From complaint intake to resolved and closed',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.red,
          steps: const [
            InsightFlowStep(
              title: 'Intake',
              subtitle: 'Register complaint',
              icon: Icons.add_alert_rounded,
            ),
            InsightFlowStep(
              title: 'Triage',
              subtitle: 'Categorize & prioritize',
              icon: Icons.rule_rounded,
            ),
            InsightFlowStep(
              title: 'Investigate',
              subtitle: 'Assign & gather facts',
              icon: Icons.manage_search_rounded,
            ),
            InsightFlowStep(
              title: 'Resolve',
              subtitle: 'Apply resolution',
              icon: Icons.task_alt_rounded,
            ),
            InsightFlowStep(
              title: 'Follow up',
              subtitle: 'Collect feedback',
              icon: Icons.feedback_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Complaint Modules
        InsightSectionTitle(
          title: 'Complaint Modules',
          subtitle: 'Tools for case management and resolution',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        complaintManagerStatsAsync.when(
          data: (stats) {
            return ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'Total Cases',
                  value: stats.totalComplaints.toString(),
                  trend: 'All complaints',
                  icon: Icons.assignment_late_rounded,
                  accent: Colors.red,
                ),
                InsightMetricCard(
                  label: 'Pending',
                  value: stats.pendingComplaints.toString(),
                  trend: 'Awaiting action',
                  icon: Icons.hourglass_top_rounded,
                  accent: Colors.orange,
                ),
                InsightMetricCard(
                  label: 'Resolved',
                  value: stats.resolvedComplaints.toString(),
                  trend: 'Completed cases',
                  icon: Icons.check_circle_rounded,
                  accent: Colors.green,
                ),
                InsightMetricCard(
                  label: 'Open',
                  value: (stats.totalComplaints -
                          stats.pendingComplaints -
                          stats.resolvedComplaints)
                      .clamp(0, stats.totalComplaints)
                      .toString(),
                  trend: 'In investigation',
                  icon: Icons.pending_rounded,
                  accent: Colors.blue,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Resolution Analytics
        InsightSectionTitle(
          title: 'Resolution Analytics',
          subtitle: 'Case status breakdown and weekly intake trend',
        ),
        const SizedBox(height: 12),
        ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 900;
                final charts = <Widget>[
                  complaintManagerStatsAsync.when(
                    data: (stats) => InsightSegmentsCard(
                      title: 'Case Status',
                      subtitle: 'Complaints by resolution stage',
                      segments: [
                        InsightSegment(
                          label: 'Pending',
                          value: stats.pendingComplaints.toDouble(),
                          color: Colors.orange,
                        ),
                        InsightSegment(
                          label: 'Open',
                          value: (stats.totalComplaints -
                                  stats.pendingComplaints -
                                  stats.resolvedComplaints)
                              .toDouble(),
                          color: Colors.blue,
                        ),
                        InsightSegment(
                          label: 'Resolved',
                          value: stats.resolvedComplaints.toDouble(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    loading: () => const PageSkeleton(type: 'card'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const InsightLineChartCard(
                    title: 'Weekly Intake',
                    subtitle: 'New complaints received over the last week',
                    accent: Colors.red,
                    points: [
                      InsightPoint('Mon', 5),
                      InsightPoint('Tue', 8),
                      InsightPoint('Wed', 6),
                      InsightPoint('Thu', 9),
                      InsightPoint('Fri', 12),
                      InsightPoint('Sat', 4),
                      InsightPoint('Sun', 2),
                    ],
                  ),
                ];
                if (twoCol) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: charts[0]),
                      const SizedBox(width: 16),
                      Expanded(child: charts[1]),
                    ],
                  );
                }
                return Column(
                  children: [
                    charts[0],
                    const SizedBox(height: 16),
                    charts[1],
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),

        // Coverage Matrix
        InsightSectionTitle(
          title: 'Complaint Coverage Matrix',
          subtitle: 'Complete overview of responsibilities',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Target'],
          rows: [
            [
              'Intake',
              'Register new complaints',
              'Complaint Details',
              'Complainants'
            ],
            [
              'Triage',
              'Prioritize & categorize',
              'Complaint Management',
              'Cases'
            ],
            [
              'Investigation',
              'Gather facts & evidence',
              'Investigation',
              'Assignees'
            ],
            [
              'Resolution',
              'Resolve & document',
              'Resolved Cases',
              'Complainants'
            ],
            [
              'Feedback',
              'Collect satisfaction',
              'Complaint Feedback',
              'Users'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activity
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('complaints')
                .select('subject, priority, status, created_at')
                .order('created_at', ascending: false)
                .limit(2),
            supabase
                .from('feedback')
                .select('feedback_type, rating, created_at')
                .order('created_at', ascending: false)
                .limit(2),
          ]),
          builder: (context, AsyncSnapshot<List<Object?>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PageSkeleton(type: 'list', itemCount: 4);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final complaints = snapshot.data![0] as List;
            final feedback = snapshot.data![1] as List;

            final List<List<String>> rows = [];

            for (var complaint in complaints) {
              final status = complaint['status']?.toString() ?? 'Open';
              final priority = complaint['priority']?.toString() ?? 'Medium';
              rows.add([
                complaint['subject']?.toString() ?? 'Complaint',
                priority,
                _timeAgo(complaint['created_at']),
                status,
              ]);
            }

            for (var item in feedback) {
              final rating = item['rating']?.toString() ?? '-';
              rows.add([
                item['feedback_type']?.toString() ?? 'Feedback',
                'Rating: $rating',
                _timeAgo(item['created_at']),
                'Received',
              ]);
            }

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest complaints and feedback',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.complaintDetails),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Item', 'Priority/Type', 'Time', 'Status'],
                  rows: rows.isEmpty
                      ? [
                          [t(L.noData, ref), '-', '-', '-'],
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
    final modules = [
      (
        'Complaints',
        Icons.assignment_late_rounded,
        Colors.red,
        AppRoutes.complaintDetails,
        'View and manage complaints',
      ),
      (
        'Resolved Cases',
        Icons.checklist_rounded,
        Colors.green,
        AppRoutes.resolved,
        'Completed complaint cases',
      ),
      (
        'Investigation',
        Icons.manage_search_rounded,
        Colors.blue,
        AppRoutes.investigation,
        'Case fact gathering',
      ),
      (
        'Complaint Feedback',
        Icons.feedback_rounded,
        Colors.orange,
        AppRoutes.complaintFeedback,
        'Satisfaction surveys',
      ),
      (
        'Complaint Management',
        Icons.support_agent_rounded,
        Colors.purple,
        AppRoutes.complaintManagement,
        'Full case control',
      ),
      (
        'Feedback',
        Icons.rate_review_rounded,
        Colors.teal,
        AppRoutes.feedback,
        'General user feedback',
      ),
    ];

    return ResponsiveBuilder(
      builder: (context, isMobile, isTablet, isDesktop) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 3,
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
            ).animate().fadeIn(delay: (index * 50).ms).scale(
                begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
          },
        );
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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: Colors.grey[500],
                      ),
                  maxLines: 2,
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
