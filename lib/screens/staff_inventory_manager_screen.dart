import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';

class StaffInventoryManagerScreen extends ConsumerStatefulWidget {
  const StaffInventoryManagerScreen({super.key});
  @override
  ConsumerState<StaffInventoryManagerScreen> createState() =>
      _StaffInventoryManagerScreenState();
}

class _StaffInventoryManagerScreenState
    extends ConsumerState<StaffInventoryManagerScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _lowStock = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final items = await _sb
          .from('inventory_items')
          .select('id')
          .lt('quantity', 10);
      setState(() {
        _lowStock = items.length;
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
          title: 'Inventory Manager',
          subtitle: 'Stock, supplies, and equipment',
          icon: Icons.inventory_2_outlined,
        ),
        const VSpace(AppSpacing.lg),
        StatCard(
          title: 'Low Stock Items',
          value: '$_lowStock',
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}
