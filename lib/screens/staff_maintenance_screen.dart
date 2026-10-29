import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffMaintenanceScreen extends ConsumerStatefulWidget {
  const StaffMaintenanceScreen({super.key});
  @override
  ConsumerState<StaffMaintenanceScreen> createState() =>
      _StaffMaintenanceScreenState();
}

class _StaffMaintenanceScreenState
    extends ConsumerState<StaffMaintenanceScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _pendingWork = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final work = await _sb
          .from('work_orders')
          .select('id')
          .eq('status', 'pending');
      setState(() {
        _pendingWork = work.length;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: AppSpacing.paddingLg,
      children: [
        const SectionHeader(
          title: 'Maintenance',
          subtitle: 'Repairs, cleaning, and facilities',
          icon: Icons.build_outlined,
        ),
        const VSpace(AppSpacing.lg),
        StatCard(
          title: 'Pending Work Orders',
          value: '$_pendingWork',
          icon: Icons.plumbing_outlined,
        ),
      ],
    );
  }
}
