import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/insight_ui.dart';

class FeatureHubScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> highlights;

  final List<InsightPoint>? points;
  final List<InsightSegment>? segments;
  final List<InsightFlowStep>? steps;
  final List<List<String>>? rows;
  final String? healthStatus;
  final String? automationStatus;
  final int? liveItems;
  final int? resolvedToday;
  final int? pendingApprovals;

  const FeatureHubScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.highlights,
    this.points,
    this.segments,
    this.steps,
    this.rows,
    this.healthStatus,
    this.automationStatus,
    this.liveItems,
    this.resolvedToday,
    this.pendingApprovals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InsightBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              InsightHeroCard(
                eyebrow: 'Operational workspace',
                title: title,
                subtitle: subtitle,
                accent: color,
                chips: [
                  InsightStatChip(
                      label: t(LDash2.highlights, ref), value: '${highlights.length}'),
                  InsightStatChip(
                      label: t(LDash2.health, ref), value: healthStatus ?? '--'),
                  InsightStatChip(
                      label: t(LDash2.automation, ref), value: automationStatus ?? '--'),
                ],
                actions: [
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Create Task'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Export'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 240,
                    child: InsightMetricCard(
                      label: t(LDash2.liveItems, ref),
                      value: liveItems?.toString() ?? '--',
                      trend: liveItems != null ? '+8.2%' : '--',
                      icon: icon,
                      accent: color,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: InsightMetricCard(
                      label: t(LDash2.resolvedToday, ref),
                      value: resolvedToday?.toString() ?? '--',
                      trend: resolvedToday != null ? '+4.6%' : '--',
                      icon: Icons.check_circle_outline_rounded,
                      accent: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    child: InsightMetricCard(
                      label: t(LDash2.pendingApprovals, ref),
                      value: pendingApprovals?.toString() ?? '--',
                      trend: pendingApprovals != null ? '-2.1%' : '--',
                      icon: Icons.pending_actions_rounded,
                      accent: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              InsightSectionTitle(
                title: '$title insights',
                subtitle:
                    'A richer workspace with charts, process visibility, and review tables.',
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 840;

                  if (narrow) {
                    return Column(
                      children: [
                        _buildTrendLine(context, ref),
                        const SizedBox(height: 16),
                        _buildDistribution(context, ref),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildTrendLine(context, ref)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDistribution(context, ref)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildProcessDiagram(context, ref),
              const SizedBox(height: 16),
              _buildTable(context, ref),
              const SizedBox(height: 16),
              InsightPromoBanner(
                title: 'Promote this module with in-app ads',
                subtitle:
                    'Turn high-performing workflows into campaigns for courses, events, or services directly from the ads hub.',
                ctaLabel: 'Open Ads',
                accent: color,
                icon: Icons.campaign_rounded,
                onTap: () => context.go('/ads'),
              ),
              const SizedBox(height: 22),
              Text(
                t(LDash2.highlights, ref),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 12),
              ...highlights.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: color.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(Icons.check_circle_rounded, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendLine(BuildContext context, WidgetRef ref) {
    if (points != null && points!.isNotEmpty) {
      return InsightLineChartCard(
        title: 'Trend line',
        subtitle: 'Current week activity across the module.',
        points: points!,
        accent: color,
      );
    }
    return _emptyCard(
      context,
      icon: Icons.show_chart_rounded,
      message: t(LDash2.noAnalytics, ref),
    );
  }

  Widget _buildDistribution(BuildContext context, WidgetRef ref) {
    if (segments != null && segments!.isNotEmpty) {
      return InsightSegmentsCard(
        title: 'Distribution',
        subtitle: 'Balanced view of healthy, pending, and urgent work.',
        segments: segments!,
      );
    }
    return _emptyCard(
      context,
      icon: Icons.pie_chart_outline_rounded,
      message: t(LDash2.noDistribution, ref),
    );
  }

  Widget _buildProcessDiagram(BuildContext context, WidgetRef ref) {
    if (steps != null && steps!.isNotEmpty) {
      return InsightProcessDiagram(
        title: 'Process diagram',
        subtitle: 'Move work from intake to completion with visible checkpoints.',
        steps: steps!,
        accent: color,
      );
    }
    return _emptyCard(
      context,
      icon: Icons.account_tree_outlined,
      message: t(LDash2.noProcessSteps, ref),
    );
  }

  Widget _buildTable(BuildContext context, WidgetRef ref) {
    final effectiveRows = rows != null && rows!.isNotEmpty
        ? rows!
        : [
            ['--', '--', 'No data', '--'],
          ];

    return InsightTableCard(
      title: 'Operational table',
      subtitle: 'Snapshot of the latest work items linked to this module.',
      columns: const ['Item', 'Owner', 'Status', 'Priority'],
      rows: effectiveRows,
    );
  }

  Widget _emptyCard(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Data will appear once this module has activity.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
