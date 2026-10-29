import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/panel_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/providers/tenant_provider.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/services/dashboard_service.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';

final _adminMetricsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return DashboardService.instance.fetchAdminMetrics();
});

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTenant = ref.watch(currentTenantProvider);
    final adminStatsAsync = ref.watch(adminStatsProvider);
    final metricsAsync = ref.watch(_adminMetricsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.adminPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'admin-dashboard',
          tables: ['students', 'classes'],
          onChange: () => ref.invalidate(_adminMetricsProvider),
        ),

        // Hero Card with real data
        if (currentTenant != null)
          InsightHeroCard(
            eyebrow: currentTenant.plan.toUpperCase(),
            title: '${t(LDash.welcomeBack, ref)} ${currentTenant.name}',
            subtitle: currentTenant.expiryDate != null
                ? '${t(LPayment.paymentDate, ref)}: ${currentTenant.expiryDate!.year}-${currentTenant.expiryDate!.month.toString().padLeft(2, '0')}-${currentTenant.expiryDate!.day.toString().padLeft(2, '0')}'
                : '',
            accent: Colors.blue,
            chips: [
              InsightStatChip(label: t(LNav.students, ref),
                value: adminStatsAsync.when(data: (s) => s.totalStudents.toString(), loading: () => '...', error: (_, __) => '0')),
              InsightStatChip(label: t(LNav.teachers, ref),
                value: adminStatsAsync.when(data: (s) => s.totalTeachers.toString(), loading: () => '...', error: (_, __) => '0')),
              InsightStatChip(label: t(LNav.classes, ref),
                value: adminStatsAsync.when(data: (s) => s.totalClasses.toString(), loading: () => '...', error: (_, __) => '0')),
            ],
            actions: [
              _GradientButton(onPressed: () => context.go('/reports'), icon: Icons.assessment_rounded, label: t(LNav.reports, ref), gradient: AppGradients.skyCyanHorizontal),
              _GradientButton(onPressed: () => context.go('/settings'), icon: Icons.settings_rounded, label: t(LNav.settings, ref), gradient: AppGradients.blueHorizontal, isOutlined: true),
            ],
          ),
        const SizedBox(height: 24),

        // Classes from DB
        InsightSectionTitle(title: t(LNav.dashboard, ref), subtitle: t(LModule.studentProgress, ref),
          trailing: TextButton.icon(onPressed: () => context.go('/reports'), icon: const Icon(Icons.arrow_forward_rounded), label: Text(t(LDash.viewAll, ref))),
        ),
        const SizedBox(height: 12),
        FutureBuilder(
          future: DashboardService.instance.fetchAdminRecentClasses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const PageSkeleton(type: 'list', itemCount: 5);
            final classes = snapshot.data ?? [];
            final rows = classes.map((cls) => [
              cls['name'] as String? ?? 'Unknown',
              (cls['student_count'] as int? ?? 0).toString(),
              'Active',
              (cls['active'] as bool? ?? true) ? 'Active' : 'Inactive',
            ]).toList();
            return InsightTableCard(
              title: '', subtitle: '',
              columns: [t(LNav.classes, ref), t(LNav.students, ref), t(LExam.score, ref), t(LPayment.status, ref)],
              rows: rows.isEmpty ? [['No classes', '-', '-', '-']] : rows,
            );
          },
        ),
        const SizedBox(height: 24),

        // Revenue + Student charts from real data
        metricsAsync.when(
          data: (m) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: InsightLineChartCard(
              title: 'Revenue Trend', subtitle: 'Collected fees',
              accent: Colors.blue,
              points: [InsightPoint('Total', ((m['collectedRevenue'] ?? 0) as double) / 1000)],
            )),
            const SizedBox(width: 16),
            Expanded(child: InsightSegmentsCard(
              title: t(LNav.departments, ref), subtitle: t(LModule.stock, ref),
              segments: [
                InsightSegment(label: 'Students', value: ((m['totalStudents'] ?? 0) as int).toDouble(), color: Colors.blue),
                InsightSegment(label: 'Teachers', value: ((m['totalTeachers'] ?? 0) as int).toDouble(), color: Colors.purple),
                InsightSegment(label: 'Departments', value: ((m['totalDepartments'] ?? 0) as int).toDouble(), color: Colors.orange),
              ],
            )),
          ]).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // Admission Process
        InsightSectionTitle(title: t(LModule.admissions, ref), subtitle: t(LModule.studentProgress, ref)),
        const SizedBox(height: 12),
        InsightProcessDiagram(title: '', subtitle: '', accent: Colors.teal, steps: const [
          InsightFlowStep(title: 'Inquiry', subtitle: 'Initial contact', icon: Icons.contact_support_rounded),
          InsightFlowStep(title: 'Application', subtitle: 'Submit documents', icon: Icons.assignment_rounded),
          InsightFlowStep(title: 'Interview', subtitle: 'Assessment test', icon: Icons.people_rounded),
          InsightFlowStep(title: 'Enrollment', subtitle: 'Fee payment & admit', icon: Icons.how_to_reg_rounded),
        ]),
        const SizedBox(height: 24),

        // Metric Cards from real data
        adminStatsAsync.when(
          data: (stats) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InsightSectionTitle(title: t(LDash.quickActions, ref), subtitle: t(LModule.analytics, ref)),
            const SizedBox(height: 12),
            ResponsiveMetricRow(children: [
              InsightMetricCard(label: t(LDash.totalStudents, ref), value: stats.totalStudents.toString(), trend: '+5% growth', icon: Icons.people_rounded, accent: Colors.blue),
              InsightMetricCard(label: t(LNav.teachers, ref), value: stats.totalTeachers.toString(), trend: '+2 new hires', icon: Icons.school_rounded, accent: Colors.blue),
              InsightMetricCard(label: t(LNav.classes, ref), value: stats.totalClasses.toString(), trend: 'Active', icon: Icons.class_rounded, accent: Colors.orange),
              InsightMetricCard(label: t(LNav.departments, ref), value: stats.totalDepartments.toString(), trend: 'Organized', icon: Icons.business_rounded, accent: Colors.purple),
            ]),
          ]),
          loading: () => const PageSkeleton(type: 'dashboard'),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // Modules
        PanelSectionTitle(title: t(LModule.feeManagement, ref)),
        PanelActionGrid(actions: [
          (t(LModule.admissions, ref), Icons.person_add_rounded, Colors.blue, () => context.go('/admissions')),
          (t(LModule.feeManagement, ref), Icons.payments_rounded, Colors.blue, () => context.go('/fee-management')),
          (t(LNav.teachers, ref), Icons.badge_rounded, Colors.orange, () => context.go('/staff-directory')),
          (t(LModule.calendar, ref), Icons.calendar_today_rounded, Colors.purple, () => context.go('/academic-year')),
          ('Create Account', Icons.person_add_rounded, Colors.black, () => context.go('/admin/create-account')),
          (t(LModule.complaints, ref), Icons.campaign_rounded, Colors.red, () => context.go('/notice-board')),
          (t(LNav.reports, ref), Icons.assessment_rounded, Colors.teal, () => context.go('/reports')),
        ]).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        const SizedBox(height: 24),

        // Recent Activity from DB
        FutureBuilder(
          future: supabase.from('classes').select().order('created_at', ascending: false).limit(4),
          builder: (context, snapshot) {
            final classes = snapshot.hasData ? (snapshot.data as List) : <dynamic>[];
            final rows = classes.map((c) => [
              'Class: ${c['name'] ?? 'Unknown'}',
              'Academic',
              'Active',
              c['active'] == true ? 'Active' : 'Inactive',
            ]).toList();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              InsightSectionTitle(title: t(LDash.recentActivity, ref), subtitle: t(LDash.upcomingEvents, ref),
                trailing: TextButton(onPressed: () => context.go('/reports'), child: Text(t(LDash.viewAll, ref)))),
              const SizedBox(height: 12),
              InsightTableCard(title: '', subtitle: '',
                columns: [t(LDash.recentActivity, ref), t(LFilter.category, ref), t(LTime.today, ref), t(LPayment.status, ref)],
                rows: rows.isEmpty ? [['No recent activity', '-', '-', '-']] : rows,
              ),
            ]);
          },
        ),
      ],
    );
  }
}


class _GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Gradient gradient;
  final bool isOutlined;
  const _GradientButton({required this.onPressed, required this.icon, required this.label, required this.gradient, this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isOutlined) {
      return Container(
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
        padding: const EdgeInsets.all(2),
        child: OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label),
          style: OutlinedButton.styleFrom(backgroundColor: theme.colorScheme.surface, foregroundColor: theme.colorScheme.primary, side: BorderSide.none, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon, color: Colors.white), label: Text(label, style: const TextStyle(color: Colors.white)),
        style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
      ),
    );
  }
}
