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

class ReceptionistPanelScreen extends ConsumerWidget {
  const ReceptionistPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receptionistStatsAsync = ref.watch(receptionistStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.receptionistPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'reception-dashboard',
          tables: ['visitors', 'leads', 'reception_events', 'phone_logs'],
          onChange: () => ref.invalidate(receptionistStatsProvider),
        ),

        // Hero Card
        receptionistStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'FRONT DESK & VISITORS',
                  title: 'Reception Command Desk',
                  subtitle:
                      'Handle visitor check-ins, capture new leads, track phone calls, and coordinate front-office events from one desk.',
                  accent: Colors.pink,
                  chips: [
                    InsightStatChip(
                      label: 'Visitors',
                      value: stats.totalVisitors.toString(),
                    ),
                    InsightStatChip(
                      label: 'Leads',
                      value: stats.totalLeads.toString(),
                    ),
                    InsightStatChip(
                      label: 'Events',
                      value: stats.totalEvents.toString(),
                    ),
                    InsightStatChip(
                      label: 'Calls',
                      value: stats.totalCalls.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.leads),
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Add Lead',
                      gradient: AppGradients.skyCyanHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.visitors),
                      icon: Icons.how_to_reg_rounded,
                      label: 'Visitor Log',
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

        // Front Desk Workflow
        InsightSectionTitle(
          title: 'Front Desk Workflow',
          subtitle: 'From first contact to admission handoff',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.pink,
          steps: const [
            InsightFlowStep(
              title: 'Greet',
              subtitle: 'Check in visitors',
              icon: Icons.front_hand_rounded,
            ),
            InsightFlowStep(
              title: 'Capture',
              subtitle: 'Log new leads',
              icon: Icons.contact_phone_rounded,
            ),
            InsightFlowStep(
              title: 'Connect',
              subtitle: 'Route to staff',
              icon: Icons.call_split_rounded,
            ),
            InsightFlowStep(
              title: 'Track',
              subtitle: 'Follow up & schedule',
              icon: Icons.track_changes_rounded,
            ),
            InsightFlowStep(
              title: 'Convert',
              subtitle: 'Hand off to admissions',
              icon: Icons.school_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Front Desk Modules
        InsightSectionTitle(
          title: 'Front Desk Modules',
          subtitle: 'Tools for reception and visitor management',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        receptionistStatsAsync.when(
          data: (stats) {
            return ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'New Leads',
                  value: stats.newLeads.toString(),
                  trend: 'Fresh prospects',
                  icon: Icons.person_add_alt_rounded,
                  accent: Colors.pink,
                ),
                InsightMetricCard(
                  label: 'Upcoming Events',
                  value: stats.upcomingEvents.toString(),
                  trend: 'On the calendar',
                  icon: Icons.event_available_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'Total Visitors',
                  value: stats.totalVisitors.toString(),
                  trend: 'All check-ins',
                  icon: Icons.people_alt_rounded,
                  accent: Colors.teal,
                ),
                InsightMetricCard(
                  label: 'Phone Logs',
                  value: stats.totalCalls.toString(),
                  trend: 'Calls handled',
                  icon: Icons.call_rounded,
                  accent: Colors.orange,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Front Desk Analytics
        InsightSectionTitle(
          title: 'Front Desk Analytics',
          subtitle: 'Lead funnel and weekly visitor trend',
        ),
        const SizedBox(height: 12),
        ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 900;
                final charts = <Widget>[
                  receptionistStatsAsync.when(
                    data: (stats) => InsightSegmentsCard(
                      title: 'Lead Funnel',
                      subtitle: 'Total leads vs brand-new prospects',
                      segments: [
                        InsightSegment(
                          label: 'Existing Pipeline',
                          value: (stats.totalLeads - stats.newLeads).toDouble(),
                          color: Colors.blue,
                        ),
                        InsightSegment(
                          label: 'New Leads',
                          value: stats.newLeads.toDouble(),
                          color: Colors.pink,
                        ),
                      ],
                    ),
                    loading: () => const PageSkeleton(type: 'card'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const InsightLineChartCard(
                    title: 'Weekly Visitors',
                    subtitle: 'Visitor check-ins over the last week',
                    accent: Colors.pink,
                    points: [
                      InsightPoint('Mon', 15),
                      InsightPoint('Tue', 22),
                      InsightPoint('Wed', 18),
                      InsightPoint('Thu', 27),
                      InsightPoint('Fri', 31),
                      InsightPoint('Sat', 12),
                      InsightPoint('Sun', 8),
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
          title: 'Reception Coverage Matrix',
          subtitle: 'Complete overview of responsibilities',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Target'],
          rows: [
            [
              'Visitors',
              'Check-in & manage guests',
              'Visitors',
              'Guests'
            ],
            [
              'Leads',
              'Capture & nurture inquiries',
              'Leads',
              'Prospects'
            ],
            [
              'Admissions',
              'Support enrollment intake',
              'Admissions',
              'Applicants'
            ],
            [
              'Events',
              'Coordinate front-desk events',
              'Events',
              'Visitors'
            ],
            [
              'Calls',
              'Log inbound/outbound calls',
              'Phone Logs',
              'Callers'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activity
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('visitors')
                .select('full_name, purpose, status, check_in')
                .order('created_at', ascending: false)
                .limit(2),
            supabase
                .from('leads')
                .select('name, interested_program, status, created_at')
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

            final visitors = snapshot.data![0] as List;
            final leads = snapshot.data![1] as List;

            final List<List<String>> rows = [];

            for (var visitor in visitors) {
              rows.add([
                visitor['full_name']?.toString() ?? 'Visitor',
                visitor['purpose']?.toString() ?? 'General',
                _timeAgo(visitor['check_in']),
                visitor['status']?.toString() ?? 'Checked in',
              ]);
            }

            for (var lead in leads) {
              final status = lead['status']?.toString() ?? 'New';
              final program = lead['interested_program']?.toString() ?? '-';
              rows.add([
                lead['name']?.toString() ?? 'Lead',
                program,
                _timeAgo(lead['created_at']),
                status,
              ]);
            }

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest visitors and new leads',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.leads),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Person', 'Purpose/Program', 'Time', 'Status'],
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
        'Visitors',
        Icons.how_to_reg_rounded,
        Colors.pink,
        AppRoutes.visitors,
        'Check-in and manage guests',
      ),
      (
        'Leads',
        Icons.person_add_alt_1_rounded,
        Colors.blue,
        AppRoutes.leads,
        'Capture and nurture prospects',
      ),
      (
        'Admissions',
        Icons.school_rounded,
        Colors.teal,
        AppRoutes.admissions,
        'Support enrollment intake',
      ),
      (
        'Event Calendar',
        Icons.event_available_rounded,
        Colors.orange,
        AppRoutes.eventCalendar,
        'View scheduled events',
      ),
      (
        'Guests',
        Icons.people_alt_rounded,
        Colors.indigo,
        AppRoutes.guests,
        'Manage special guests',
      ),
      (
        'Messages',
        Icons.forum_rounded,
        Colors.purple,
        AppRoutes.messages,
        'Internal front-desk chat',
      ),
      (
        'Notifications',
        Icons.notifications_active_rounded,
        Colors.green,
        AppRoutes.notifications,
        'Alerts and reminders',
      ),
      (
        'Feedback',
        Icons.feedback_rounded,
        Colors.brown,
        AppRoutes.feedback,
        'Visitor satisfaction',
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
