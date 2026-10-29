import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffSecurityScreen extends ConsumerStatefulWidget {
  const StaffSecurityScreen({super.key});
  @override
  ConsumerState<StaffSecurityScreen> createState() =>
      _StaffSecurityScreenState();
}

class _StaffSecurityScreenState extends ConsumerState<StaffSecurityScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _todayLogs = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final logs = await _sb
          .from('security_logs')
          .select('id')
          .eq('log_date', today);
      setState(() {
        _todayLogs = logs.length;
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
          title: 'Security',
          subtitle: 'Access control and surveillance',
          icon: Icons.security_outlined,
        ),
        const VSpace(AppSpacing.lg),
        StatCard(
          title: 'Today\'s Logs',
          value: '$_todayLogs',
          icon: Icons.notification_important_outlined,
        ),
      ],
    );
  }
}
