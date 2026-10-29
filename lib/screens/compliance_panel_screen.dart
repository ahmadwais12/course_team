import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/widgets/curved_bottom_nav.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class CompliancePanelScreen extends ConsumerStatefulWidget {
  const CompliancePanelScreen({super.key});

  @override
  ConsumerState<CompliancePanelScreen> createState() => _CompliancePanelScreenState();
}

class _CompliancePanelScreenState extends ConsumerState<CompliancePanelScreen> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _inspections = [];
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final inspections = await Supabase.instance.client.from('inspections').select().order('created_at', ascending: false).limit(10);
      final pending = inspections.where((i) => i['status']?.toString().toLowerCase() == 'pending').length;
      if (mounted) {
        setState(() {
          _inspections = inspections;
          _pendingCount = pending;
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        title: Text(AppLocalizations.translate(LCompliancePS.compliance, locale)),
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
          const Text('Error loading inspections'),
          const SizedBox(height: 8),
          Text(_error!, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
    }

    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        SectionHeader(
          title: AppLocalizations.translate(LCompliancePS.complianceOverview, locale),
          subtitle: AppLocalizations.translate(LCompliancePS.inspectionsLicensesInsurance, locale),
          icon: Icons.verified_user_outlined,
        ),
        const VSpace(AppSpacing.lg),
        if (_pendingCount > 0)
          AppBanner(
            message: '$_pendingCount ${AppLocalizations.translate(LCompliancePS.upcomingInspections, locale)}',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
        if (_pendingCount == 0)
          AppBanner(
            message: AppLocalizations.translate(LCompliancePS.upcomingInspections, locale),
            icon: Icons.check_circle_outline,
            color: Colors.blue,
          ),
        const VSpace(AppSpacing.lg),
        if (_inspections.isNotEmpty)
          AppTable<Map<String, dynamic>>(
            columns: [
              AppLocalizations.translate(LColumn.item, locale),
              AppLocalizations.translate(LColumn.cType, locale),
              AppLocalizations.translate(LColumn.due, locale),
              AppLocalizations.translate(LColumn.status, locale),
            ],
            rows: _inspections,
            rowBuilder: (context, row) {
              final item = row['item']?.toString() ?? row['name']?.toString() ?? '—';
              final type = row['type']?.toString() ?? row['inspection_type']?.toString() ?? '—';
              final due = row['due_date']?.toString() ?? row['date']?.toString() ?? '—';
              final status = row['status']?.toString() ?? '—';
              final isPending = status.toLowerCase() == 'pending';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(width: 160, child: Text(item)),
                    SizedBox(width: 160, child: Text(type)),
                    SizedBox(width: 160, child: Text(due)),
                    SizedBox(width: 160, child: InfoBadge(
                      label: status,
                      color: isPending ? Colors.orange : Colors.blue,
                    )),
                  ],
                ),
              );
            },
          ),
        if (_inspections.isEmpty)
          EmptyState(
            icon: Icons.verified_user_outlined,
            title: 'No Inspections',
            message: 'No inspection records found',
          ),
      ],
    );
  }
}
