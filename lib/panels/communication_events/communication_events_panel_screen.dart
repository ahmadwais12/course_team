import 'package:flutter/material.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class CommunicationEventsPanelScreen extends ConsumerWidget {
  const CommunicationEventsPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communicationStatsAsync = ref.watch(communicationStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.eventManagerPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'communication-dashboard',
          tables: ['announcements', 'events', 'feedback', 'notifications'],
          onChange: () => ref.invalidate(communicationStatsProvider),
        ),

        // Hero Card
        communicationStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'ENGAGEMENT & COMMUNICATION',
                  title: 'Communication Command Center',
                  subtitle:
                      'Handle announcements, events, notifications, feedback, and user engagement from one unified panel.',
                  accent: Colors.purple,
                  chips: [
                    InsightStatChip(
                      label: 'Announcements',
                      value: stats.announcements.toString(),
                    ),
                    InsightStatChip(
                      label: t(LDash.upcomingEvents, ref),
                      value: stats.upcomingEvents.toString(),
                    ),
                    InsightStatChip(
                      label: 'Open Tickets',
                      value: stats.openTickets.toString(),
                    ),
                    InsightStatChip(
                      label: 'Notifications',
                      value: stats.pendingNotifications.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.noticeBoard),
                      icon: Icons.campaign_rounded,
                      label: 'New Announcement',
                      gradient: AppGradients.skyCyanHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.notifications),
                      icon: Icons.notifications_rounded,
                      label: 'Send Notification',
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

        // Communication Workflow
        InsightSectionTitle(
          title: 'Communication Workflow',
          subtitle: 'From announcement to resolution - complete communication lifecycle',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.purple,
          steps: const [
            InsightFlowStep(
              title: 'Announce',
              subtitle: 'Create message',
              icon: Icons.campaign_rounded,
            ),
            InsightFlowStep(
              title: 'Target',
              subtitle: 'Select audience',
              icon: Icons.people_rounded,
            ),
            InsightFlowStep(
              title: 'Deliver',
              subtitle: 'Send via channels',
              icon: Icons.send_rounded,
            ),
            InsightFlowStep(
              title: 'Track',
              subtitle: 'Monitor engagement',
              icon: Icons.analytics_rounded,
            ),
            InsightFlowStep(
              title: 'Feedback',
              subtitle: 'Collect responses',
              icon: Icons.feedback_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Communication & Events Modules
        InsightSectionTitle(
          title: 'Communication & Events Modules',
          subtitle: 'Comprehensive tools for engagement and event management',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        communicationStatsAsync.when(
          data: (stats) {
            return ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'Active Events',
                  value: stats.activeEvents.toString(),
                  trend: 'Live now',
                  icon: Icons.event_available_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'Registrations',
                  value: stats.totalRegistrations.toString(),
                  trend: 'Event signups',
                  icon: Icons.how_to_reg_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'In Progress',
                  value: stats.inProgressTickets.toString(),
                  trend: 'Being handled',
                  icon: Icons.pending_rounded,
                  accent: Colors.orange,
                ),
                InsightMetricCard(
                  label: 'Resolved Today',
                  value: stats.resolvedToday.toString(),
                  trend: 'Completed',
                  icon: Icons.check_circle_rounded,
                  accent: Colors.purple,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Coverage Matrix
        InsightSectionTitle(
          title: 'Panel Coverage Matrix',
          subtitle: 'Complete overview of responsibilities',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Target'],
          rows: [
            [
              'Announcements',
              'Create & manage course-wide messages',
              'Notice Board',
              'All Users'
            ],
            [
              'Notifications',
              'Push, email, SMS alerts',
              'Notifications',
              'Targeted Groups'
            ],
            [
              'Messaging',
              'Internal communication',
              'Messages',
              'Staff/Students'
            ],
            [
              'Events',
              'Create & manage events',
              'Event Calendar',
              'Participants'
            ],
            [
              'Support',
              'Complaints & feedback',
              'Helpdesk',
              'Requesters'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activity
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('announcements')
                .select('title, audience, created_at')
                .order('created_at', ascending: false)
                .limit(2),
            supabase
                .from('complaints')
                .select('title, status, priority, created_at')
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

            final announcements = snapshot.data![0] as List;
            final complaints = snapshot.data![1] as List;

            final List<List<String>> rows = [];

            for (var ann in announcements) {
              rows.add([
                ann['title']?.toString() ?? 'Announcement',
                'Announcement',
                ann['audience']?.toString() ?? 'All',
                _timeAgo(ann['created_at']),
                'Active',
              ]);
            }

            for (var comp in complaints) {
              final status = comp['status']?.toString() ?? 'Open';
              final priority = comp['priority']?.toString() ?? 'Medium';
              rows.add([
                comp['title']?.toString() ?? 'Ticket',
                'Support Ticket',
                priority,
                _timeAgo(comp['created_at']),
                status,
              ]);
            }

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest announcements and support tickets',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.reports),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Item', 'Type', 'Target/Priority', 'Time', 'Status'],
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
    final modules = [
      (
        'Announcements',
        Icons.campaign_rounded,
        Colors.red,
        AppRoutes.noticeBoard,
        'Create and manage course-wide announcements',
      ),
      (
        'Notifications',
        Icons.notifications_active_rounded,
        Colors.blue,
        AppRoutes.notifications,
        'Send push, email, and SMS notifications',
      ),
      (
        'Messages',
        Icons.message_rounded,
        Colors.blue,
        AppRoutes.messages,
        'Internal messaging system',
      ),
      (
        'Event Calendar',
        Icons.calendar_month_rounded,
        Colors.orange,
        AppRoutes.eventCalendar,
        'Create and manage events',
      ),
      (
        'Venues',
        Icons.meeting_room_rounded,
        Colors.purple,
        AppRoutes.venues,
        'Manage event venues and rooms',
      ),
      (
        'Ticketing',
        Icons.confirmation_number_rounded,
        Colors.teal,
        AppRoutes.complaintDetails,
        'Handle complaints and tickets',
      ),
      (
        'Support Hub',
        Icons.support_agent_rounded,
        Colors.pink,
        AppRoutes.helpdesk,
        'Customer support and helpdesk',
      ),
      (
        'Feedback',
        Icons.feedback_rounded,
        Colors.indigo,
        AppRoutes.feedback,
        'Collect and manage feedback',
      ),
      (
        'Broadcast',
        Icons.campaign_rounded,
        Colors.cyan,
        AppRoutes.noticeBoard,
        'Broadcast messages to groups',
      ),
      (
        'Guest Lists',
        Icons.people_rounded,
        Colors.brown,
        AppRoutes.guests,
        'Manage event participants',
      ),
      (
        'Auto Schedule',
        Icons.schedule_rounded,
        Colors.lime,
        AppRoutes.eventCalendar,
        'Automated event scheduling',
      ),
      (
        'Analytics',
        Icons.analytics_rounded,
        Colors.grey,
        AppRoutes.reports,
        'Communication and engagement reports',
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
