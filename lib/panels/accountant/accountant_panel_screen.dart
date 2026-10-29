import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/widgets/base_panel_layout.dart';
import 'package:course_emis/widgets/panel_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:course_emis/widgets/insight_ui.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/providers/panel_stats_provider.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/realtime_watcher.dart';

class AccountantPanelScreen extends ConsumerWidget {
  const AccountantPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountantStatsAsync = ref.watch(accountantStatsProvider);
    final supabase = Supabase.instance.client;

    return BasePanelLayout(
      title: t(LPanel.accountantPanel, ref),
      children: [
        RealtimeDashboardWatcher(
          channelName: 'accountant-dashboard',
          tables: ['payments', 'invoices', 'expenses'],
          onChange: () => ref.invalidate(accountantStatsProvider),
        ),

        // Hero Card with Financial Summary
        accountantStatsAsync
            .when(
              data: (stats) {
                return InsightHeroCard(
                  eyebrow: 'FINANCIAL DASHBOARD',
                  title: 'Finance Overview',
                  subtitle:
                      'Manage course finances, track revenue, expenses, and fee collections efficiently.',
                  accent: Colors.blue,
                  chips: [
                    InsightStatChip(
                        label: 'Invoices',
                        value: stats.totalInvoices.toString()),
                    InsightStatChip(
                        label: 'Pending',
                        value: '\$${stats.pendingAmount.toStringAsFixed(0)}'),
                    InsightStatChip(
                        label: 'Discounts',
                        value: stats.totalDiscounts.toString()),
                  ],
                  actions: [
                    _GradientButton(
                      onPressed: () => context.go('/payments'),
                      icon: Icons.payments_rounded,
                      label: 'Collect Fee',
                      gradient: AppGradients.skyCyanHorizontal,
                    ),
                    _GradientButton(
                      onPressed: () => context.go('/reports'),
                      icon: Icons.assessment_rounded,
                      label: t(LNav.reports, ref),
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

        // Section: Fee Collection Status Table
        InsightSectionTitle(
          title: 'Fee Collection Status',
          subtitle: 'Pending and overdue payments by grade',
          trailing: TextButton.icon(
            onPressed: () => context.go('/payments'),
            icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(t(LPayment.makePayment, ref)),
          ),
        ),
        const SizedBox(height: 12),
        InsightTableCard(
          title: '',
          subtitle: '',
          columns: const [
            'Grade',
            'Total Students',
            'Paid',
            'Pending',
            'Collection %'
          ],
          rows: const [
            ['Grade 1-5', '120', '105', '15', '87.5%'],
            ['Grade 6-8', '95', '88', '7', '92.6%'],
            ['Grade 9-10', '85', '78', '7', '91.8%'],
            ['Grade 11-12', '65', '52', '13', '80.0%'],
          ],
        ),
        const SizedBox(height: 24),

        // Section: Revenue & Expense Analytics
        _buildFinancialAnalytics(context, ref, supabase),
        const SizedBox(height: 24),

        // Section: Fee Collection Process
        InsightSectionTitle(
          title: 'Fee Collection Workflow',
          subtitle: 'Standard procedure for collecting fees',
        ),
        const SizedBox(height: 12),
        InsightProcessDiagram(
          title: '',
          subtitle: '',
          accent: Colors.orange,
          steps: const [
            InsightFlowStep(
              title: 'Generate',
              subtitle: 'Create invoice',
              icon: Icons.receipt_long_rounded,
            ),
            InsightFlowStep(
              title: 'Notify',
              subtitle: 'Send to parent',
              icon: Icons.notifications_rounded,
            ),
            InsightFlowStep(
              title: 'Collect',
              subtitle: 'Receive payment',
              icon: Icons.payments_rounded,
            ),
            InsightFlowStep(
              title: 'Receipt',
              subtitle: 'Confirm & record',
              icon: Icons.check_circle_rounded,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Metric Cards
        _buildFinancialMetrics(context, ref, supabase),
        const SizedBox(height: 24),

        // Section: Finance Modules
        const PanelSectionTitle(title: 'Finance Modules'),
        PanelActionGrid(
          actions: [
            (
              'Fee Collection',
              Icons.payments_rounded,
              Colors.blue,
              () => context.go('/payments')
            ),
            (
              'Invoices',
              Icons.receipt_long_rounded,
              Colors.blue,
              () => context.go('/invoices')
            ),
            (
              'Payments',
              Icons.history_rounded,
              Colors.orange,
              () => context.go('/payment-history')
            ),
            (
              'Expenses',
              Icons.shopping_cart_rounded,
              Colors.red,
              () => context.go('/expenses')
            ),
            (
              'Salaries',
              Icons.people_rounded,
              Colors.purple,
              () => context.go('/salaries')
            ),
            (
              'Reports',
              Icons.assessment_rounded,
              Colors.teal,
              () => context.go('/reports')
            ),
            (
              'Discounts',
              Icons.local_offer_rounded,
              Colors.pink,
              () => context.go('/discounts')
            ),
            (
              'Budget',
              Icons.savings_rounded,
              Colors.indigo,
              () => context.go('/budget')
            ),
            (
              'Taxation',
              Icons.gavel_rounded,
              Colors.brown,
              () => context.go('/taxation')
            ),
          ],
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
        const SizedBox(height: 24),

        // Section: Recent Transactions from Database
        FutureBuilder(
          future: supabase
              .from('invoices')
              .select()
              .order('created_at', ascending: false)
              .limit(4),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const PageSkeleton(type: 'table');
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final invoices = snapshot.data as List;
            final rows = invoices.map((inv) {
              final status = inv['status'] as String? ?? 'Pending';
              final amount = inv['amount'] as num? ?? 0;
              return [
                'Invoice #${inv['invoice_number'] ?? 'N/A'}',
                status == 'Paid' ? 'Income' : 'Pending',
                _timeAgo(inv['created_at']),
                '\$${amount.toStringAsFixed(0)}',
                status,
              ];
            }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InsightSectionTitle(
                  title: t(LDash.recentActivity, ref),
                  subtitle: 'Latest financial activities',
                  trailing: TextButton(
                    onPressed: () => context.go('/payment-history'),
                    child: Text(t(LDash.viewAll, ref)),
                  ),
                ),
                const SizedBox(height: 12),
                InsightTableCard(
                  title: '',
                  subtitle: '',
                  columns: const [
                    'Transaction',
                    'Type',
                    'Time',
                    'Amount',
                    'Status'
                  ],
                  rows: rows.isEmpty
                      ? [
                          [t(L.noData, ref), '-', '-', '-', '-']
                        ]
                      : rows,
                ),
              ],
            );
          },
        ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
      ],
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

  Widget _buildFinancialAnalytics(
      BuildContext context, WidgetRef ref, SupabaseClient supabase) {
    return FutureBuilder(
      future: Future.wait([
        supabase
            .from('payments')
            .select('amount, created_at')
            .order('created_at', ascending: true)
            .limit(6)
            .withConverter((data) => data as List<dynamic>),
        supabase
            .from('expenses')
            .select('amount, category')
            .order('created_at', ascending: false)
            .limit(100)
            .withConverter((data) => data as List<dynamic>),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        final months = ['Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan'];
        List<InsightPoint> revenuePoints = [];
        List<InsightSegment> expenseSegments = [];

        if (snapshot.hasData) {
          final payments = snapshot.data![0] as List;
          final expenses = snapshot.data![1] as List;

          // Build revenue trend
          for (int i = 0; i < payments.length && i < 6; i++) {
            final amount =
                double.tryParse(payments[i]['amount']?.toString() ?? '0') ?? 0;
            final monthIdx = i < months.length ? i : months.length - 1;
            revenuePoints.add(
                InsightPoint(months[monthIdx], (amount / 1000).toDouble()));
          }

          // Build expense breakdown
          Map<String, double> categoryTotals = {};
          for (final expense in expenses) {
            final category = expense['category']?.toString() ?? 'Other';
            final amount =
                double.tryParse(expense['amount']?.toString() ?? '0') ?? 0;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          if (categoryTotals.isNotEmpty) {
            final total =
                categoryTotals.values.fold<double>(0, (sum, val) => sum + val);
            final colors = [
              Colors.blue,
              Colors.orange,
              Colors.purple,
              Colors.teal,
              Colors.red,
              Colors.blue
            ];
            int colorIdx = 0;

            categoryTotals.forEach((category, amount) {
              expenseSegments.add(
                InsightSegment(
                  label: category,
                  value: ((amount / total) * 100).toDouble(),
                  color: colors[colorIdx % colors.length],
                ),
              );
              colorIdx++;
            });
          }
        }

        if (revenuePoints.isEmpty) {
          revenuePoints = [
            InsightPoint('Aug', 0),
            InsightPoint('Sep', 0),
            InsightPoint('Oct', 0),
          ];
          expenseSegments = [
            InsightSegment(label: t(L.noData, ref), value: 100, color: Colors.grey),
          ];
        }

        return Column(
          children: [
            InsightSectionTitle(
              title: 'Financial Analytics',
              subtitle: 'Revenue trends and expense breakdown',
            ),
            const SizedBox(height: 12),
            ResponsiveMetricRow(
              spacing: 16,
              children: [
                InsightLineChartCard(
                  title: 'Revenue Trend',
                  subtitle: 'Last 6 months',
                  accent: Colors.blue,
                  points: revenuePoints,
                ),
                InsightSegmentsCard(
                  title: 'Expense Breakdown',
                  subtitle: 'Current month',
                  segments: expenseSegments,
                ),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
          ],
        );
      },
    );
  }

  Widget _buildFinancialMetrics(BuildContext context, WidgetRef ref, SupabaseClient supabase) {
    return FutureBuilder(
      future: Future.wait([
        supabase
            .from('payments')
            .select('amount')
            .withConverter((data) => data as List<dynamic>),
        supabase
            .from('invoices')
            .select('amount, status')
            .eq('status', 'Pending')
            .withConverter((data) => data as List<dynamic>),
        supabase
            .from('expenses')
            .select('amount')
            .gte(
                'created_at',
                DateTime(DateTime.now().year, DateTime.now().month, 1)
                    .toIso8601String())
            .withConverter((data) => data as List<dynamic>),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        double totalRevenue = 0;
        double pendingFees = 0;
        double monthlyExpenses = 0;
        int pendingCount = 0;

        if (snapshot.hasData) {
          final payments = snapshot.data![0] as List;
          final invoices = snapshot.data![1] as List;
          final expenses = snapshot.data![2] as List;

          totalRevenue = payments.fold<double>(
              0,
              (sum, p) =>
                  sum + (double.tryParse(p['amount']?.toString() ?? '0') ?? 0));
          pendingFees = invoices.fold<double>(
              0,
              (sum, inv) =>
                  sum +
                  (double.tryParse(inv['amount']?.toString() ?? '0') ?? 0));
          pendingCount = invoices.length;
          monthlyExpenses = expenses.fold<double>(
              0,
              (sum, e) =>
                  sum + (double.tryParse(e['amount']?.toString() ?? '0') ?? 0));
        }

        final netProfit = totalRevenue - monthlyExpenses;

        return Column(
          children: [
            InsightSectionTitle(
              title: 'Financial Metrics',
              subtitle: 'Key performance indicators',
            ),
            const SizedBox(height: 12),
            ResponsiveMetricRow(
              children: [
                InsightMetricCard(
                  label: 'Total Revenue',
                  value: '\$${(totalRevenue / 1000).toStringAsFixed(1)}K',
                  trend: totalRevenue > 0 ? 'Collected' : 'None',
                  icon: Icons.attach_money_rounded,
                  accent: Colors.blue,
                ),
                InsightMetricCard(
                  label: 'Pending Fees',
                  value: '\$${(pendingFees / 1000).toStringAsFixed(1)}K',
                  trend: '$pendingCount students',
                  icon: Icons.pending_actions_rounded,
                  accent: Colors.orange,
                ),
                InsightMetricCard(
                  label: 'Monthly Expenses',
                  value: '\$${(monthlyExpenses / 1000).toStringAsFixed(1)}K',
                  trend: 'This month',
                  icon: Icons.money_off_rounded,
                  accent: Colors.red,
                ),
                InsightMetricCard(
                  label: 'Net Profit',
                  value: '\$${(netProfit / 1000).toStringAsFixed(1)}K',
                  trend: netProfit > 0 ? 'Positive' : 'Negative',
                  icon: Icons.account_balance_rounded,
                  accent: Colors.blue,
                ),
              ],
            ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
          ],
        );
      },
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
