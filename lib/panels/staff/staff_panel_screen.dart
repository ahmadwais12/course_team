import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/panel_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:course_emis/nav.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/core/responsive/responsive.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';

class StaffPanelScreen extends ConsumerWidget {
  const StaffPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePanelLayout(
      title: t(LPanel.staffPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'staff-dashboard',
          tables: ['users', 'announcements'],
          onChange: () => debugPrint('[StaffPanel] DB data changed — refresh dashboard'),
        ),

        // Hero Card - Staff Hub Overview
        InsightHeroCard(
          eyebrow: t(LNav.dashboard, ref),
          title: t(LNav.dashboard, ref),
          subtitle: t(LDash.recentActivity, ref),
          accent: Colors.indigo,
          chips: [
            const InsightStatChip(label: 'Sub-Panels', value: '5'),
            InsightStatChip(label: t(LNav.departments, ref), value: '5'),
            const InsightStatChip(label: 'Staff', value: 'Active'),
          ],
          actions: [
            _GradientButton(
              onPressed: () => context.go(AppRoutes.hrManagerPanel),
              icon: Icons.people_rounded,
              label: t(LPanel.hrManagerPanel, ref),
              gradient: AppGradients.skyCyanHorizontal,
            ),
            _GradientButton(
              onPressed: () => context.go(AppRoutes.accountantPanel),
              icon: Icons.account_balance_rounded,
              label: t(LPanel.accountantPanel, ref),
              gradient: AppGradients.blueHorizontal,
              isOutlined: true,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Staff Sub-Panels Grid
        InsightSectionTitle(
          title: t(LNav.dashboard, ref),
          subtitle:
              'All 5 specialized departments for institutional operations',
        ),
        const SizedBox(height: 16),
        _buildSubPanelGrid(context, ref),
        const SizedBox(height: 24),

        // Panel Workflow
        InsightSectionTitle(
          title: t(LNav.dashboard, ref),
          subtitle: 'How staff panels interact with each other',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.deepPurple,
          steps: [
            InsightFlowStep(
              title: t(LPanel.hrManagerPanel, ref),
              subtitle: 'Creates Teachers',
              icon: Icons.person_add_rounded,
            ),
            InsightFlowStep(
              title: t(LPanel.academicSupportPanel, ref),
              subtitle: 'Assigns to Course',
              icon: Icons.school_rounded,
            ),
            InsightFlowStep(
              title: t(LPanel.academicSupportPanel, ref),
              subtitle: 'Creates Students',
              icon: Icons.group_add_rounded,
            ),
            InsightFlowStep(
              title: t(LPanel.accountantPanel, ref),
              subtitle: 'Handles Fees',
              icon: Icons.payments_rounded,
            ),
            InsightFlowStep(
              title: t(LPanel.eventManagerPanel, ref),
              subtitle: 'Sends Notifications',
              icon: Icons.campaign_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Access Modules
        InsightSectionTitle(
          title: 'Quick Access Modules',
          subtitle: 'Common tasks across all staff panels',
        ),
        const SizedBox(height: 12),
        PanelActionGrid(
          actions: [
            (
              t(LNav.profile, ref),
              Icons.person_rounded,
              Colors.blue,
              () => context.go(AppRoutes.profile)
            ),
            (
              'Staff Directory',
              Icons.contacts_rounded,
              Colors.blue,
              () => context.go(AppRoutes.staffDirectory)
            ),
            (
              t(LModule.leaveManagement, ref),
              Icons.beach_access_rounded,
              Colors.orange,
              () => context.go(AppRoutes.leaveManagement)
            ),
            (
              'Notice Board',
              Icons.campaign_rounded,
              Colors.red,
              () => context.go(AppRoutes.noticeBoard)
            ),
            (
              t(LNav.messages, ref),
              Icons.message_rounded,
              Colors.purple,
              () => context.go(AppRoutes.messages)
            ),
            (
              t(LNav.settings, ref),
              Icons.settings_rounded,
              Colors.grey,
              () => context.go(AppRoutes.settings)
            ),
          ],
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        const SizedBox(height: 24),

        // Panel Responsibility Matrix
        InsightSectionTitle(
          title: 'Panel Responsibility Matrix',
          subtitle: 'Clear separation of duties across panels',
        ),
        const SizedBox(height: 12),
        InsightTableCard(
          title: '',
          subtitle: '',
          columns: const ['Panel', 'Manages', 'Never Accesses', 'Key Role'],
          rows: [
            [
              t(LPanel.academicSupportPanel, ref),
              'Students Only',
              'Staff Records',
              'Student Lifecycle'
            ],
            [
              t(LPanel.hrManagerPanel, ref),
              'Staff Only',
              'Student Records',
              'Staff Lifecycle'
            ],
            [
              t(LPanel.accountantPanel, ref),
              'Fees, Salaries',
              'Academic Data',
              'Financial Control'
            ],
            [
              t(LPanel.itSupportPanel, ref),
              'Users, Security',
              'Financial Data',
              'Technical Support'
            ],
            [
              t(LPanel.eventManagerPanel, ref),
              'Events, Messages',
              'Core Operations',
              'Engagement'
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSubPanelGrid(BuildContext context, WidgetRef ref) {
    final subPanels = [
      (
        t(LPanel.accountantPanel, ref),
        'Student fees, salaries, expenses, reports',
        Icons.account_balance_wallet_rounded,
        Colors.blue,
        AppRoutes.accountantPanel,
      ),
      (
        t(LPanel.academicSupportPanel, ref),
        'Students, classes, attendance, grades',
        Icons.school_rounded,
        Colors.indigo,
        AppRoutes.academicSupportPanel,
      ),
      (
        t(LPanel.hrManagerPanel, ref),
        'Staff, payroll, attendance, contracts',
        Icons.people_rounded,
        Colors.orange,
        AppRoutes.hrManagerPanel,
      ),
      (
        t(LPanel.itSupportPanel, ref),
        'Users, devices, tickets, security',
        Icons.computer_rounded,
        Colors.blue,
        AppRoutes.itSupportPanel,
      ),
      (
        t(LPanel.eventManagerPanel, ref),
        'Announcements, events, feedback, notifications',
        Icons.campaign_rounded,
        Colors.purple,
        AppRoutes.communicationEventsPanel,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: context.isMobile ? 1.5 : 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: subPanels.length,
      itemBuilder: (context, index) {
        final panel = subPanels[index];
        return _buildSubPanelCard(
          context,
          panel.$1,
          panel.$2,
          panel.$3,
          panel.$4,
          panel.$5,
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildSubPanelCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: color.withValues(alpha: 0.5),
                      size: 16,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
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
