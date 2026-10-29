import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/providers/tenant_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/services/dashboard_service.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';
// Realtime stream for super admin dashboard
final _superAdminMetricsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return DashboardService.instance.fetchSuperAdminMetrics();
});

class SuperAdminPanelScreen extends ConsumerWidget {
  const SuperAdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenants = ref.watch(tenantProvider);
    final metricsAsync = ref.watch(_superAdminMetricsProvider);

    return BasePanelLayout(
      title: t(LPanel.superAdminPanel, ref),
      children: [
        // Realtime-triggered refresh — auto-invalidates metrics provider
        RealtimeDashboardWatcher(
          channelName: 'super-admin-dashboard',
          tables: ['tenants', 'users'],
          onChange: () => ref.invalidate(_superAdminMetricsProvider),
        ),

        metricsAsync.when(
          data: (m) => Column(children: [
            _buildStatsGrid(context, ref, m),
            const SizedBox(height: 24),
            _buildActivityRow(context, ref, m),
          ]),
          loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => _buildStatsGrid(context, ref, {
            'totalTenants': tenants.length,
            'activeTenants': tenants.where((t) => t.isActive).length,
            'totalUsers': 0, 'totalStudents': 0, 'totalTeachers': 0, 'totalStaff': 0,
          }),
        ),
        const SizedBox(height: 24),

        // Data Table: Recent Tenants from DB
        _buildTenantDataTable(context, ref, tenants),
        const SizedBox(height: 24),

        // Progress Cards with real data
        metricsAsync.when(
          data: (m) => _buildProgressRow(context, ref, m),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // Tenant Grid
        _buildSectionTitle(context, ref, t(LModule.courses, ref)),
        const SizedBox(height: 12),
        _buildTenantGrid(context, ref, tenants),
        const SizedBox(height: 24),
        _buildSectionTitle(context, ref, t(LSettings.general, ref)),
        const SizedBox(height: 12),
        _buildModuleGrid(context, ref),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, WidgetRef ref, String title) {
    return Row(
      children: [
        Container(
          width: 4, height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // --- Stats Grid from real DB ---
  Widget _buildStatsGrid(BuildContext context, WidgetRef ref, Map<String, dynamic> m) {
    final total = (m['totalTenants'] ?? 0) as int;
    final active = (m['activeTenants'] ?? 0) as int;
    final users = (m['totalUsers'] ?? 0) as int;
    final students = (m['totalStudents'] ?? 0) as int;
    final teachers = (m['totalTeachers'] ?? 0) as int;
    final staff = (m['totalStaff'] ?? 0) as int;

    final stats = [
      ('Total Tenants', total.toString(), Icons.business_rounded, Colors.blue, '$active active'),
      ('Total Users', users.toString(), Icons.people_rounded, Colors.green, 'All profiles'),
      ('Students', students.toString(), Icons.school_rounded, Colors.orange, 'Enrolled'),
      ('Teachers', teachers.toString(), Icons.person_rounded, Colors.purple, 'Teaching staff'),
      ('Staff', staff.toString(), Icons.badge_rounded, Colors.teal, 'Support staff'),
      ('Admins', (total > 0 ? (users ~/ total).toString() : '0'), Icons.admin_panel_settings_rounded, Colors.indigo, 'Per tenant'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 3,
        childAspectRatio: context.isMobile ? 1.4 : 1.2,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return _buildEnhancedStatCard(context, s.$1, s.$2, s.$3, s.$4, s.$5)
            .animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildEnhancedStatCard(BuildContext context, String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            Icon(Icons.trending_up_rounded, color: color, size: 16),
          ]),
          const Spacer(),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 10)),
        ]),
      ),
    );
  }

  // --- Activity Row: Recent Activity from DB ---
  Widget _buildActivityRow(BuildContext context, WidgetRef ref, Map<String, dynamic> m) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DashboardService.instance.fetchSuperAdminActivity(),
      builder: (context, snapshot) {
        final tenants = snapshot.data ?? [];
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _CardContainer(
                title: 'Recent Activity',
                subtitle: 'Latest registered tenants',
                child: tenants.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(t(LAll.all_no_recent_activity, ref), style: TextStyle(color: Colors.grey[500])),
                      )
                    : Column(
                        children: tenants.map((t) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (t['is_active'] == true ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                t['is_active'] == true ? Icons.add_business_rounded : Icons.business_rounded,
                                color: t['is_active'] == true ? Colors.green : Colors.grey, size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t['name']?.toString() ?? 'Tenant',
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                Text(t['slug']?.toString() ?? '',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                              ]),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (t['is_active'] == true ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(t['is_active'] == true ? 'Active' : 'Inactive',
                                style: TextStyle(fontSize: 10, color: t['is_active'] == true ? Colors.green : Colors.grey, fontWeight: FontWeight.bold)),
                            ),
                          ]),
                        )).toList(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _CardContainer(
                title: 'Snapshot',
                subtitle: 'Key metrics at a glance',
                child: Column(children: [
                  _DonutProgressCard(title: 'Active Rate', percent: (m['totalTenants'] ?? 1) > 0
                    ? ((m['activeTenants'] ?? 0) / (m['totalTenants'] ?? 1)).toDouble() : 0,
                    color: Colors.green, detail: '${m['activeTenants'] ?? 0} / ${m['totalTenants'] ?? 0}'),
                  const SizedBox(height: 8),
                  _DonutProgressCard(title: 'Student Ratio', percent: (m['totalUsers'] ?? 1) > 0
                    ? ((m['totalStudents'] ?? 0) / (m['totalUsers'] ?? 1)).toDouble() : 0,
                    color: Colors.blue, detail: '${m['totalStudents'] ?? 0} students'),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Tenants Data Table from DB ---
  Widget _buildTenantDataTable(BuildContext context, WidgetRef ref, List<Tenant> tenants) {
    final rows = tenants.take(5).toList();
    if (rows.isEmpty) return const SizedBox.shrink();
    return _CardContainer(
      title: 'Recent Registrations',
      subtitle: 'Latest tenants registered',
      child: SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: DataTable(columns: [
          DataColumn(label: Text(t(LColumn.name, ref), style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t(LAll.all_plan, ref), style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t(LAll.all_location, ref), style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(t(LColumn.status, ref), style: TextStyle(fontWeight: FontWeight.bold))),
        ], rows: rows.map((t) {
          final planColor = _getPlanColor(t.plan);
          return DataRow(cells: [
            DataCell(Row(children: [
              _TenantAvatar(tenant: t, radius: 16, color: planColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ])),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: planColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(t.plan, style: TextStyle(color: planColor, fontSize: 12, fontWeight: FontWeight.bold)),
            )),
            DataCell(Text(t.location ?? '-', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
            DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: t.isActive ? Colors.green : Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(t.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, color: t.isActive ? Colors.green : Colors.grey)),
            ])),
          ]);
        }).toList()),
      ),
    );
  }

  // --- Progress Row with real data ---
  Widget _buildProgressRow(BuildContext context, WidgetRef ref, Map<String, dynamic> m) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _CardContainer(
            title: 'User Distribution',
            subtitle: 'Breakdown of all platform users',
            child: SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _barItem(context, ref, 'Students', ((m['totalStudents'] ?? 0) as int), Colors.blue),
                  _barItem(context, ref, 'Teachers', ((m['totalTeachers'] ?? 0) as int), Colors.green),
                  _barItem(context, ref, 'Staff', ((m['totalStaff'] ?? 0) as int), Colors.orange),
                  _barItem(context, ref, 'Admins', ((m['totalUsers'] ?? 0) as int) - ((m['totalStudents'] ?? 0) as int) - ((m['totalTeachers'] ?? 0) as int) - ((m['totalStaff'] ?? 0) as int), Colors.purple),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildActivityList(context, ref),
        ),
      ],
    );
  }

  Widget _barItem(BuildContext context, WidgetRef ref, String label, int count, Color color) {
    final maxVal = math.max(count, 1);
    final maxHeight = 140.0;
    final fraction = count > 0 ? (count / maxVal).clamp(0.05, 1.0) : 0.05;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(tt(LAll.all_s392, ref, ['$count']), style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            height: fraction * maxHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [color, color.withValues(alpha: 0.3)]),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildActivityList(BuildContext context, WidgetRef ref) {
    final activities = [
      ('System initialized', 'Platform ready', Icons.check_circle_rounded, Colors.green),
      ('${(ref.watch(_superAdminMetricsProvider).valueOrNull?['totalTenants'] ?? 0)} tenants', 'Registered', Icons.business_rounded, Colors.blue),
      ('${(ref.watch(_superAdminMetricsProvider).valueOrNull?['activeTenants'] ?? 0)} active', 'Currently running', Icons.play_circle_rounded, Colors.teal),
      ('All systems operational', 'Health check passed', Icons.monitor_heart_rounded, Colors.orange),
    ];

    return _CardContainer(
      title: t(LDash.recentActivity, ref),
      subtitle: 'System overview',
      child: Column(
        children: activities.map((a) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: a.$4.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(a.$3, color: a.$4, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(a.$2, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              ]),
            ),
          ]),
        )).toList(),
      ),
    );
  }

  // --- Tenant Grid ---
  Widget _buildTenantGrid(BuildContext context, WidgetRef ref, List<Tenant> tenants) {
    if (tenants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.business_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(t(L.noData, ref), style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ]),
      ).animate().fadeIn();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 3,
        childAspectRatio: context.isMobile ? 1.3 : 1.6,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: tenants.length,
      itemBuilder: (context, index) {
        final tenant = tenants[index];
        final color = _getPlanColor(tenant.plan);
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: InkWell(
            onTap: () { ref.read(currentTenantProvider.notifier).state = tenant; context.go(AppRoutes.adminPanel); },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Expanded(child: Row(children: [
                    _TenantAvatar(tenant: tenant, radius: 16, color: color),
                    const SizedBox(width: 8),
                    Flexible(child: Text(tenant.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(tenant.plan, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ]),
                const Spacer(),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(child: Text(tenant.location ?? 'No location', style: TextStyle(color: Colors.grey[500], fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: 0.7, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 4),
              ]),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildModuleGrid(BuildContext context, WidgetRef ref) {
    final modules = [
      (t(LModule.tenantManagement, ref), Icons.admin_panel_settings_rounded, Colors.purple, AppRoutesAll.tenants),
      (t(LSettings.general, ref), Icons.settings_rounded, Colors.grey, AppRoutesAll.systemSettings),
      ('Backup & Restore', Icons.backup_rounded, Colors.teal, AppRoutesAll.backupRestore),
      (t(LModule.systemLogs, ref), Icons.article_rounded, Colors.orange, AppRoutesAll.systemLogs),
      (t(LModule.apiIntegrations, ref), Icons.api_rounded, Colors.indigo, AppRoutesAll.apiIntegrations),
      ('Create User', Icons.person_add_alt_1, Colors.black, AppRoutesAll.userCreation),
      ('Multi-language', Icons.language_rounded, Colors.blue, AppRoutesAll.multiLanguage),
      (t(LModule.logs, ref), Icons.history_rounded, Colors.brown, AppRoutesAll.recordHistory),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.isMobile ? 2 : 3,
        childAspectRatio: context.isMobile ? 1.2 : 1,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final m = modules[index];
        return _buildModuleCard(context, m.$1, m.$2, m.$3, m.$4)
            .animate().fadeIn(delay: (index * 50).ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildModuleCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(route),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'premium': return Colors.indigo;
      case 'enterprise': return Colors.amber;
      case 'basic': return Colors.blue;
      default: return Colors.cyan;
    }
  }
}

// -------------------------------
//  Shared widgets
// -------------------------------
class _CardContainer extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _CardContainer({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TextStyle(color: Colors.grey[500], fontSize: 12))],
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class _DonutProgressCard extends ConsumerWidget {
  final String title;
  final double percent;
  final Color color;
  final String detail;
  const _DonutProgressCard({required this.title, required this.percent, required this.color, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        SizedBox(width: 40, height: 40, child: Stack(fit: StackFit.expand, children: [
          CircularProgressIndicator(value: percent, strokeWidth: 5,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color)),
          Center(child: Text(tt(LAll.all_s3, ref, ['${(percent * 100).toInt()}']), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color))),
        ])),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(detail, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        ])),
      ]),
    );
  }
}

class _TenantAvatar extends StatelessWidget {
  final Tenant tenant;
  final double radius;
  final Color? color;
  const _TenantAvatar({required this.tenant, this.radius = 16, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blue;
    final url = tenant.logoUrl?.trim();
    final fallback =
        Icon(Icons.business_rounded, color: c, size: radius * 0.8);
    if (url == null || url.isEmpty) {
      return CircleAvatar(
          radius: radius,
          backgroundColor: c.withValues(alpha: 0.15),
          child: fallback);
    }
    return ClipOval(
      child: Image.network(
        url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: radius,
          backgroundColor: c.withValues(alpha: 0.15),
          child: fallback,
        ),
      ),
    );
  }
}
