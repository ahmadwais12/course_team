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

class MaintenancePanelScreen extends ConsumerWidget {
  const MaintenancePanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceStatsAsync = ref.watch(maintenanceStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.maintenancePanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'maintenance-dashboard',
          tables: ['work_orders', 'maintenance_requests', 'equipment', 'vendors'],
          onChange: () => ref.invalidate(maintenanceStatsProvider),
        ),

        // Hero Card
        maintenanceStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'FACILITIES & EQUIPMENT',
                  title: 'Maintenance Operations Hub',
                  subtitle:
                      'Track work orders, dispatch repair teams, monitor equipment health, and manage service vendors from one console.',
                  accent: Colors.orange,
                  chips: [
                    InsightStatChip(
                      label: 'Total Orders',
                      value: stats.totalWorkOrders.toString(),
                    ),
                    InsightStatChip(
                      label: 'Pending',
                      value: stats.pendingTasks.toString(),
                    ),
                    InsightStatChip(
                      label: 'In Progress',
                      value: stats.inProgressTasks.toString(),
                    ),
                    InsightStatChip(
                      label: 'Completed',
                      value: stats.completedTasks.toString(),
                    ),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.workOrders),
                      icon: Icons.construction_rounded,
                      label: 'Work Orders',
                      gradient: AppGradients.orangeAmberHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go(AppRoutes.equipmentStatus),
                      icon: Icons.handyman_rounded,
                      label: 'Equipment Status',
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

        // Service Workflow
        InsightSectionTitle(
          title: 'Service Workflow',
          subtitle: 'From reported fault to completed repair',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.orange,
          steps: const [
            InsightFlowStep(
              title: 'Report',
              subtitle: 'Log maintenance issue',
              icon: Icons.report_problem_rounded,
            ),
            InsightFlowStep(
              title: 'Assign',
              subtitle: 'Dispatch a team',
              icon: Icons.assignment_ind_rounded,
            ),
            InsightFlowStep(
              title: 'Repair',
              subtitle: 'Perform the work',
              icon: Icons.build_rounded,
            ),
            InsightFlowStep(
              title: 'Verify',
              subtitle: 'Quality check',
              icon: Icons.verified_rounded,
            ),
            InsightFlowStep(
              title: 'Complete',
              subtitle: 'Close work order',
              icon: Icons.task_alt_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Maintenance Modules
        InsightSectionTitle(
          title: 'Maintenance Modules',
          subtitle: 'Tools for facilities and equipment upkeep',
        ),
        const SizedBox(height: 12),
        _buildModulesGrid(context),
        const SizedBox(height: 24),

        // Analytics Row
        maintenanceStatsAsync.when(
          data: (stats) {
            return ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'Work Orders',
                  value: stats.totalWorkOrders.toString(),
                  trend: 'All time',
                  icon: Icons.assignment_rounded,
                  accent: Colors.orange,
                ),
                InsightMetricCard(
                  label: 'Pending',
                  value: stats.pendingTasks.toString(),
                  trend: 'Not yet assigned',
                  icon: Icons.hourglass_empty_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'In Progress',
                  value: stats.inProgressTasks.toString(),
                  trend: 'Being worked on',
                  icon: Icons.pending_rounded,
                  accent: Colors.amber,
                ),
                InsightMetricCard(
                  label: 'Completed',
                  value: stats.completedTasks.toString(),
                  trend: 'Avg ${stats.avgResolutionTime}',
                  icon: Icons.check_circle_rounded,
                  accent: Colors.green,
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
        const SizedBox(height: 24),

        // Maintenance Analytics
        InsightSectionTitle(
          title: 'Maintenance Analytics',
          subtitle: 'Order pipeline and weekly completion trend',
        ),
        const SizedBox(height: 12),
        ResponsiveBuilder(
          builder: (context, isMobile, isTablet, isDesktop) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth >= 900;
                final charts = <Widget>[
                  maintenanceStatsAsync.when(
                    data: (stats) => InsightSegmentsCard(
                      title: 'Order Pipeline',
                      subtitle: 'Work orders by current stage',
                      segments: [
                        InsightSegment(
                          label: 'Pending',
                          value: stats.pendingTasks.toDouble(),
                          color: Colors.blue,
                        ),
                        InsightSegment(
                          label: 'In Progress',
                          value: stats.inProgressTasks.toDouble(),
                          color: Colors.amber,
                        ),
                        InsightSegment(
                          label: 'Completed',
                          value: stats.completedTasks.toDouble(),
                          color: Colors.green,
                        ),
                      ],
                    ),
                    loading: () => const PageSkeleton(type: 'card'),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const InsightLineChartCard(
                    title: 'Weekly Completions',
                    subtitle: 'Work orders completed over the last week',
                    accent: Colors.orange,
                    points: [
                      InsightPoint('Mon', 6),
                      InsightPoint('Tue', 9),
                      InsightPoint('Wed', 7),
                      InsightPoint('Thu', 11),
                      InsightPoint('Fri', 13),
                      InsightPoint('Sat', 5),
                      InsightPoint('Sun', 3),
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
          title: 'Maintenance Coverage Matrix',
          subtitle: 'Complete overview of responsibilities',
        ),
        const SizedBox(height: 12),
        const InsightTableCard(
          title: '',
          subtitle: '',
          columns: ['Area', 'Responsibility', 'Primary Tool', 'Target'],
          rows: [
            [
              'Scheduling',
              'Plan preventive work',
              'Maintenance Schedule',
              'Facilities'
            ],
            [
              'Work Orders',
              'Track repairs & tasks',
              'Work Orders',
              'Technicians'
            ],
            [
              'Equipment',
              'Monitor asset health',
              'Equipment Status',
              'Departments'
            ],
            [
              'Vendors',
              'Manage service providers',
              'Vendors',
              'Suppliers'
            ],
            [
              'Logs',
              'Record maintenance history',
              'Maintenance Logs',
              'Audit'
            ],
          ],
        ),
        const SizedBox(height: 24),

        // Recent Activity
        FutureBuilder(
          future: Future.wait([
            supabase
                .from('maintenance_requests')
                .select('title, location, status, created_at')
                .order('created_at', ascending: false)
                .limit(2),
            supabase
                .from('work_orders')
                .select('title, priority, status, created_at')
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

            final requests = snapshot.data![0] as List;
            final orders = snapshot.data![1] as List;

            final List<List<String>> rows = [];

            for (var req in requests) {
              rows.add([
                req['title']?.toString() ?? 'Maintenance Request',
                req['location']?.toString() ?? '-',
                _timeAgo(req['created_at']),
                req['status']?.toString() ?? 'Reported',
              ]);
            }

            for (var order in orders) {
              final status = order['status']?.toString() ?? 'Pending';
              final priority = order['priority']?.toString() ?? 'Medium';
              rows.add([
                order['title']?.toString() ?? 'Work Order',
                priority,
                _timeAgo(order['created_at']),
                status,
              ]);
            }

            return Column(
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest maintenance requests and work orders',
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.workOrders),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const ['Item', 'Detail', 'Time', 'Status'],
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
        'Maintenance Schedule',
        Icons.calendar_month_rounded,
        Colors.orange,
        AppRoutes.maintSchedule,
        'Plan preventive maintenance',
      ),
      (
        'Work Orders',
        Icons.construction_rounded,
        Colors.blue,
        AppRoutes.workOrders,
        'Create & track repair tasks',
      ),
      (
        'Equipment Status',
        Icons.handyman_rounded,
        Colors.teal,
        AppRoutes.equipmentStatus,
        'Monitor asset health',
      ),
      (
        'Maintenance Logs',
        Icons.history_rounded,
        Colors.indigo,
        AppRoutes.maintLogs,
        'Full service history',
      ),
      (
        'Vendors',
        Icons.business_rounded,
        Colors.purple,
        AppRoutes.vendors,
        'Manage service providers',
      ),
      (
        'Equipment',
        Icons.precision_manufacturing_rounded,
        Colors.green,
        AppRoutes.equipmentStatus,
        'Facility asset inventory',
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
