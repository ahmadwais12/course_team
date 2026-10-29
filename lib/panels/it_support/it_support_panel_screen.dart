import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/panel_widgets.dart';
import 'package:course_emis/widgets/motion_ui.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';

class ITSupportPanelScreen extends ConsumerWidget {
  const ITSupportPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itStatsAsync = ref.watch(itStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.itSupportPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'it-dashboard',
          tables: ['support_tickets', 'it_devices'],
          onChange: () => ref.invalidate(itStatsProvider),
        ),

        const PanelSectionTitle(title: 'Infrastructure Overview'),
        itStatsAsync
            .when(
              data: (stats) {
                return TiltCard(
                  child: PanelStatGrid(
                    stats: [
                      (
                        'Open Tickets',
                        stats.openTickets.toString(),
                        Icons.report_problem_rounded,
                        Colors.red,
                        'Priority'
                      ),
                      (
                        'Resolved',
                        stats.resolvedTickets.toString(),
                        Icons.check_circle_rounded,
                        Colors.blue,
                        'This Week'
                      ),
                      (
                        'Active Devices',
                        stats.totalDevices.toString(),
                        Icons.devices_rounded,
                        Colors.blue,
                        'Managed'
                      ),
                      (
                        'System Uptime',
                        stats.systemUptime,
                        Icons.speed_rounded,
                        Colors.purple,
                        'Healthy'
                      ),
                    ],
                  ),
                );
              },
              loading: () => const PageSkeleton(type: 'dashboard'),
              error: (e, st) => TiltCard(
                child: PanelStatGrid(
                  stats: [
                    ('Error', '0', Icons.error_rounded, Colors.red, ''),
                    ('Error', '0', Icons.error_rounded, Colors.red, ''),
                    ('Error', '0', Icons.error_rounded, Colors.red, ''),
                    ('Error', '0', Icons.error_rounded, Colors.red, ''),
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2, end: 0),
        const PanelSectionTitle(title: 'Support Operations'),
        PanelActionGrid(
          actions: [
            (
              'Ticketing Hub',
              Icons.confirmation_number_rounded,
              Colors.red,
              () => context.go('/helpdesk')
            ),
            (
              'Device Inventory',
              Icons.inventory_2_rounded,
              Colors.blue,
              () => context.go('/it-assets')
            ),
            (
              'Bug Reports',
              Icons.bug_report_rounded,
              Colors.orange,
              () => context.go('/incident-logs')
            ),
            (
              'System Health',
              Icons.monitor_heart_rounded,
              Colors.purple,
              () => context.go('/system-status')
            ),
            (
              'Network Status',
              Icons.network_check_rounded,
              Colors.teal,
              () => context.go('/network-monitoring')
            ),
            (
              'Backups/Recovery',
              Icons.backup_rounded,
              Colors.pink,
              () => context.go('/licenses')
            ),
            (
              'System Updates',
              Icons.system_update_rounded,
              Colors.indigo,
              () => context.go('/helpdesk')
            ),
            (
              'IT Assets',
              Icons.laptop_mac_rounded,
              Colors.cyan,
              () => context.go('/it-assets')
            ),
            (
              'Support Logs',
              Icons.history_rounded,
              Colors.grey,
              () => context.go('/incident-logs')
            ),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
        const SizedBox(height: 24),
        _buildITQuickStats(context, ref),
        const SizedBox(height: 24),
        const PanelSectionTitle(title: 'Recent Tickets'),
        _buildRecentTickets(context, ref, supabase)
            .animate()
            .fadeIn(delay: 400.ms)
            .slideX(begin: 0.1, end: 0),
      ],
    );
  }

  Widget _buildITQuickStats(BuildContext context, WidgetRef ref) {
    final itStatsAsync = ref.watch(itStatsProvider);

    return itStatsAsync.when(
      data: (stats) {
        return ResponsiveMetricRow(
          children: [
            _buildMini('Open', stats.openTickets.toString(),
                Colors.red, Icons.report_problem_rounded),
            _buildMini('Resolved', stats.resolvedTickets.toString(),
                Colors.blue, Icons.check_circle_rounded),
            _buildMini('Devices', stats.totalDevices.toString(),
                Colors.blue, Icons.devices_rounded),
          ],
        );
      },
      loading: () => const Row(
        children: [
          Expanded(child: PageSkeleton(type: 'list', itemCount: 3)),
        ],
      ),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildMini(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildTicketItem(BuildContext context, String title, String subtitle,
      String time, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Text(
          time,
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
        onTap: () => context.go('/helpdesk'),
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

  Widget _buildRecentTickets(BuildContext context, WidgetRef ref, SupabaseClient supabase) {
    return FutureBuilder(
      future: supabase
          .from('support_tickets')
          .select(
              'id, title, description, status, priority, location, created_at')
          .order('created_at', ascending: false)
          .limit(3)
          .withConverter((data) => data as List<dynamic>),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PageSkeleton(type: 'list', itemCount: 3);
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Column(
            children: [
              _buildTicketItem(
                context,
                t(L.noData, ref),
                'No support tickets found',
                '-',
                Colors.grey,
                Icons.info_rounded,
              ),
            ],
          );
        }

        final tickets = snapshot.data!;
        final ticketWidgets = <Widget>[];

        for (int i = 0; i < tickets.length && i < 3; i++) {
          final ticket = tickets[i];
          final priority =
              ticket['priority']?.toString().toLowerCase() ?? 'medium';
          Color priorityColor;

          switch (priority) {
            case 'high':
            case 'urgent':
              priorityColor = Colors.red;
              break;
            case 'medium':
              priorityColor = Colors.orange;
              break;
            default:
              priorityColor = Colors.blue;
          }

          IconData ticketIcon;
          final title = ticket['title']?.toString() ?? 'Untitled';
          if (title.toLowerCase().contains('wifi') ||
              title.toLowerCase().contains('network')) {
            ticketIcon = Icons.wifi_off_rounded;
          } else if (title.toLowerCase().contains('printer')) {
            ticketIcon = Icons.print_disabled_rounded;
          } else if (title.toLowerCase().contains('account')) {
            ticketIcon = Icons.person_add_rounded;
          } else {
            ticketIcon = Icons.build_rounded;
          }

          ticketWidgets.add(
            _buildTicketItem(
              context,
              title,
              '${ticket['location'] ?? 'N/A'} • ${ticket['description'] ?? 'No description'}',
              _timeAgo(ticket['created_at']),
              priorityColor,
              ticketIcon,
            )
                .animate()
                .fadeIn(delay: (400 + (i * 100)).ms)
                .slideX(begin: 0.1, end: 0),
          );
        }

        return Column(children: ticketWidgets);
      },
    );
  }
}
