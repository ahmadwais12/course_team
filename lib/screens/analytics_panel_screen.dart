import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/widgets/curved_bottom_nav.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:intl/intl.dart';

class AnalyticsPanelScreen extends ConsumerStatefulWidget {
  const AnalyticsPanelScreen({super.key});

  @override
  ConsumerState<AnalyticsPanelScreen> createState() => _AnalyticsPanelScreenState();
}

class _AnalyticsPanelScreenState extends ConsumerState<AnalyticsPanelScreen> {
  bool _loading = true;
  String? _error;

  double _utilization = 0;
  double _totalRevenue = 0;
  int _totalStudents = 0;
  int _activeStudents = 0;
  double _attendanceRate = 0;
  List<double> _monthlyRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final payments = await Supabase.instance.client.from('payments').select('amount, status, payment_date');
      final students = await Supabase.instance.client.from('students').select('id, status, enrollment_date');
      final attendance = await Supabase.instance.client.from('attendance').select('status');

      final completedPayments = payments.where((p) => p['status'] == 'completed').toList();
      final totalRevenue = completedPayments.fold<double>(0, (sum, p) => sum + (p['amount'] is num ? (p['amount'] as num).toDouble() : 0));

      final totalStudents = students.length;
      final activeStudents = students.where((s) => s['status'] == 'active').length;

      final totalAttendance = attendance.length;
      final presentAttendance = attendance.where((a) => a['status'] == 'present').length;
      final attendanceRate = totalAttendance > 0 ? presentAttendance / totalAttendance : 0.0;

      final utilization = totalStudents > 0 ? activeStudents / totalStudents : 0.0;

      Map<int, double> monthlyMap = {};
      for (final p in completedPayments) {
        if (p['payment_date'] != null) {
          final date = DateTime.tryParse(p['payment_date'].toString());
          if (date != null) {
            final key = date.year * 100 + date.month;
            monthlyMap[key] = (monthlyMap[key] ?? 0) + (p['amount'] is num ? (p['amount'] as num).toDouble() : 0);
          }
        }
      }
      final sortedMonths = monthlyMap.keys.toList()..sort();
      final recentKeys = sortedMonths.length > 7 ? sortedMonths.sublist(sortedMonths.length - 7) : sortedMonths;
      final monthlyRevenue = recentKeys.map((k) => monthlyMap[k]!).toList();

      if (mounted) {
        setState(() {
          _totalRevenue = totalRevenue;
          _totalStudents = totalStudents;
          _activeStudents = activeStudents;
          _attendanceRate = attendanceRate;
          _utilization = utilization;
          _monthlyRevenue = monthlyRevenue;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role']?.toString().toLowerCase() ?? 'staff';
    final locale = ref.watch(localeProvider);
    final navItems = getRoleNavItems(role, locale);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Text(AppLocalizations.translate(LAnalyticsPS.analytics, locale)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      bottomNavigationBar: buildCurvedBottomNavBar(
        context: context,
        currentIndex: 0,
        items: navItems,
        onItemTap: (i) {
          if (i == 0) context.go('/');
        },
        onMoreTap: () => showCurvedMoreSheet(context, ref, role),
        locale: locale,
      ),
      body: _buildBody(theme, locale),
    );
  }

  Widget _buildBody(ThemeData theme, String locale) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(AppLocalizations.translate(L.error, locale), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: Text(AppLocalizations.translate(L.retry, locale))),
        ],
      ),
    );
    }

    final utilPercent = (_utilization * 100).toStringAsFixed(0);
    final costDisplay = NumberFormat.compact(locale: 'en_US').format(_totalRevenue);
    final attPercent = (_attendanceRate * 100).toStringAsFixed(0);

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppLocalizations.translate(LAnalyticsPS.performanceAnalytics, locale),
            subtitle: AppLocalizations.translate(LAnalyticsPS.utilizationCostsTrends, locale),
            icon: Icons.analytics_outlined,
          ),
          const VSpace(AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              SizedBox(
                width: 320,
                child: StatCard(
                  title: AppLocalizations.translate(LAnalyticsPS.utilization, locale),
                  value: '$utilPercent%',
                  icon: Icons.insights,
                  progress: _utilization,
                ),
              ),
              SizedBox(
                width: 320,
                child: StatCard(
                  title: AppLocalizations.translate(LDash2.totalRevenue, locale),
                  value: 'PKR $costDisplay',
                  icon: Icons.paid_outlined,
                  progress: _totalRevenue > 0 ? 1.0 : 0,
                ),
              ),
              SizedBox(
                width: 320,
                child: StatCard(
                  title: AppLocalizations.translate(LDash2.attendanceRate, locale),
                  value: '$attPercent%',
                  icon: Icons.check_circle_outline,
                  progress: _attendanceRate,
                ),
              ),
              SizedBox(
                width: 320,
                child: StatCard(
                  title: AppLocalizations.translate(LDash2.activeStudents, locale),
                  value: '$_activeStudents / $_totalStudents',
                  icon: Icons.people_outline,
                  progress: _utilization,
                ),
              ),
            ],
          ),
          const VSpace(AppSpacing.lg),
          if (_monthlyRevenue.isNotEmpty)
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: SizedBox(
                height: 220,
                child: _AnalyticsTrend(
                  color: theme.colorScheme.primary,
                  values: _monthlyRevenue,
                ),
              ),
            ),
          if (_monthlyRevenue.isEmpty)
            EmptyState(
              icon: Icons.show_chart,
              title: AppLocalizations.translate(LDash2.noRevenueData, locale),
              message: AppLocalizations.translate(LDash2.paymentRecordsHere, locale),
            ),
        ],
      ),
    );
  }
}

class _AnalyticsTrend extends StatelessWidget {
  final Color color;
  final List<double> values;

  const _AnalyticsTrend({required this.color, required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: values
          .map(
            (value) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.compact(locale: 'en_US').format(value),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: value / maxValue,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  color,
                                  color.withValues(alpha: 0.35),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
