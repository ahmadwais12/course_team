import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/widgets/motion.dart';
import 'package:course_emis/widgets/curved_bottom_nav.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class DispatchPanelScreen extends ConsumerStatefulWidget {
  const DispatchPanelScreen({super.key});

  @override
  ConsumerState<DispatchPanelScreen> createState() => _DispatchPanelScreenState();
}

class _DispatchPanelScreenState extends ConsumerState<DispatchPanelScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _trips = [];
  int _ongoingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final trips = await Supabase.instance.client.from('trips').select().order('created_at', ascending: false).limit(10);
      final ongoing = trips.where((t) => t['status'] == 'active' || t['status'] == 'en_route').length;
      if (mounted) {
        setState(() {
          _trips = trips;
          _ongoingCount = ongoing;
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
        title: Text(AppLocalizations.translate(LDispatchPS.dispatch, locale)),
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
      body: _buildBody(locale),
    );
  }

  Widget _buildBody(String locale) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error loading trips'),
          const SizedBox(height: 8),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
    }

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: AppLocalizations.translate(LDispatchPS.dispatchCenter, locale),
            subtitle: AppLocalizations.translate(LDispatchPS.assignTrackModifyTrips, locale),
            icon: Icons.local_shipping_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: AppLocalizations.translate(LDispatchPS.ongoingTrips, locale),
            value: '$_ongoingCount',
            icon: Icons.directions_run,
            progress: _ongoingCount > 0 ? (_ongoingCount / (_trips.isNotEmpty ? _trips.length : 1)).clamp(0, 1) : 0,
          ),
          const VSpace(AppSpacing.md),
          if (_trips.isNotEmpty)
            AppTable<Map<String, dynamic>>(
              columns: [
                AppLocalizations.translate(LColumn.trip, locale),
                AppLocalizations.translate(LColumn.driver, locale),
                AppLocalizations.translate(LColumn.vehicle, locale),
                AppLocalizations.translate(LColumn.status, locale),
              ],
              rows: _trips,
              rowBuilder: (context, row) {
                final tripId = row['trip_id']?.toString() ?? row['id']?.toString() ?? '—';
                final driver = row['driver_name']?.toString() ?? row['driver']?.toString() ?? '—';
                final vehicle = row['vehicle_no']?.toString() ?? row['vehicle']?.toString() ?? '—';
                final status = row['status']?.toString() ?? '—';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 160, child: Text(tripId)),
                      SizedBox(width: 160, child: Text(driver)),
                      SizedBox(width: 160, child: Text(vehicle)),
                      SizedBox(width: 160, child: InfoBadge(label: status)),
                    ],
                  ),
                );
              },
            ),
          if (_trips.isEmpty)
            FadeSlide(
              child: EmptyState(
                icon: Icons.assignment,
                title: AppLocalizations.translate(LDispatchPS.noModifications, locale),
                message: AppLocalizations.translate(LDispatchPS.modifyTripToSee, locale),
              ),
            ),
        ],
      ),
    );
  }
}
