import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/widgets/motion.dart';
import 'package:course_emis/widgets/curved_bottom_nav.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class OperationsPanelScreen extends ConsumerStatefulWidget {
  const OperationsPanelScreen({super.key});

  @override
  ConsumerState<OperationsPanelScreen> createState() => _OperationsPanelScreenState();
}

class _OperationsPanelScreenState extends ConsumerState<OperationsPanelScreen> {
  bool _loading = true;
  String? _error;

  int _scheduleCount = 0;
  int _pendingAssignments = 0;
  List<Map<String, dynamic>> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final schedules = await Supabase.instance.client.from('schedules').select().order('created_at', ascending: false).limit(10);
      final activeTripsRes = await Supabase.instance.client.from('trips').select('id').eq('status', 'active');
      final activeTripsCount = activeTripsRes.length;
      final pendingCount = schedules.where((s) => s['status']?.toString().toLowerCase() == 'pending').length;

      if (mounted) {
        setState(() {
          _schedules = schedules;
          _scheduleCount = schedules.length;
          _pendingAssignments = pendingCount + activeTripsCount;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role']?.toString().toLowerCase() ?? 'staff';
    final locale = ref.watch(localeProvider);
    final navItems = getRoleNavItems(role, locale);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.translate(LOperationsPS.operations, locale)),
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
      body: _buildBody(theme: Theme.of(context), locale: locale),
    );
  }

  Widget _buildBody({required ThemeData theme, required String locale}) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(t(LGen.somethingWentWrong, ref)),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: Text(t(LGen.tryAgain, ref))),
        ],
      ),
    );
    }

    final availability = _scheduleCount > 0 ? (_scheduleCount - _pendingAssignments) / _scheduleCount : 0.0;

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlide(
            child: SectionHeader(
              title: AppLocalizations.translate(LOperationsPS.dailyOperations, locale),
              subtitle: AppLocalizations.translate(LOperationsPS.availabilityScheduling, locale),
              icon: Icons.assignment_rounded,
              action: FilledButton(
                onPressed: () => context.go('/my-schedule'),
                child: Text(AppLocalizations.translate(LOperationsPS.newSchedule, locale)),
              ),
            ),
          ),
          const VSpace(AppSpacing.lg),
          FadeSlide(
            child: Wrap(
              runSpacing: AppSpacing.md,
              spacing: AppSpacing.md,
              children: [
                SizedBox(
                  width: 300,
                  child: StatCard(
                    title: AppLocalizations.translate(LOperationsPS.activeSchedules, locale),
                    value: '$_scheduleCount',
                    icon: Icons.event_available,
                    trendLabel: AppLocalizations.translate(LTime.today, locale),
                    progress: _scheduleCount > 0 ? 1.0 : 0,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: StatCard(
                    title: AppLocalizations.translate(LOperationsPS.pendingAssignments, locale),
                    value: '$_pendingAssignments',
                    icon: Icons.pending_actions,
                    progress: _pendingAssignments > 0 ? (_pendingAssignments / (_scheduleCount > 0 ? _scheduleCount : 1)).clamp(0, 1) : 0,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: StatCard(
                    title: AppLocalizations.translate(LOperationsPS.availability, locale),
                    value: '${(availability * 100).toStringAsFixed(0)}%',
                    icon: Icons.fact_check,
                    progress: availability,
                  ),
                ),
              ],
            ),
          ),
          const VSpace(AppSpacing.lg),
          FadeSlide(
            child: _pendingAssignments == 0
                ? AppBanner(
                    message: AppLocalizations.translate(LOperationsPS.noConflicts, locale),
                    icon: Icons.check_circle_outline,
                    color: Colors.blue,
                  )
                : AppBanner(
                    message: '$_pendingAssignments pending items require attention',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
          ),
          const VSpace(AppSpacing.lg),
          FadeSlide(
            child: MapCardPlaceholder(height: 240),
          ),
          const VSpace(AppSpacing.lg),
          if (_schedules.isEmpty)
            FadeSlide(
              child: EmptyState(
                icon: Icons.event_note_outlined,
                title: AppLocalizations.translate(LOperationsPS.noUpcomingDispatches, locale),
                message: AppLocalizations.translate(LOperationsPS.createScheduleToSee, locale),
                actionText: AppLocalizations.translate(LOperationsPS.createSchedule, locale),
                onAction: () => context.go('/my-schedule'),
              ),
            ),
          if (_schedules.isNotEmpty)
            FadeSlide(
              child: AppCard(
                pressable: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(LTitle.departments, ref), style: theme.textTheme.titleMedium),
                    const VSpace(AppSpacing.md),
                    ..._schedules.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(s['title']?.toString() ?? s['name']?.toString() ?? '—', style: theme.textTheme.bodyMedium)),
                          InfoBadge(label: s['status']?.toString() ?? '—'),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
