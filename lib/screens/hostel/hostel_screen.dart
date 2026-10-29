import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class HostelScreen extends ConsumerStatefulWidget {
  const HostelScreen({super.key});
  @override
  ConsumerState<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends ConsumerState<HostelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _allocations = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tenantId = _sb.auth.currentUser?.userMetadata?['tenant_id'];
      var q = _sb.from('hostel_rooms').select();
      if (tenantId != null) q = q.eq('tenant_id', tenantId);
      final rooms = await q.order('room_number');
      final allocs = await _sb
          .from('hostel_allocations')
          .select('*, students(student_code)')
          .eq('status', 'active')
          .order('allocated_at', ascending: false);
      setState(() {
        _rooms = List<Map<String, dynamic>>.from(rooms);
        _allocations = List<Map<String, dynamic>>.from(allocs);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'available':
        return Colors.blue;
      case 'full':
        return Colors.red;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> get _filtered => _filter == 'all'
      ? _rooms
      : _rooms.where((r) => r['status'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LTitle.hostel, ref)),
        bottom: TabBar(
          controller: _tabs,
          tabs: [Tab(text: t(LModule.library, ref)), Tab(text: t(LStatus.cNew, ref))],
        ),
      ),
      body: _loading
          ? const PageSkeleton(type: 'list')
          : TabBarView(
              controller: _tabs,
              children: [_roomsTab(), _allocTab()],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _roomsTab() {
    final counts = {'available': 0, 'full': 0, 'maintenance': 0};
    for (final r in _rooms) {
      final s = r['status'] as String? ?? 'available';
      counts[s] = (counts[s] ?? 0) + 1;
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: counts.entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _StatusChip(
                          label:
                              '${e.key[0].toUpperCase()}${e.key.substring(1)}: ${e.value}',
                          color: _statusColor(e.key),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: ['all', 'available', 'full', 'maintenance']
                .map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(s[0].toUpperCase() + s.substring(1)),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? const Center(child: Text('No rooms'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final r = _filtered[i];
                    final color = _statusColor(r['status'] ?? 'available');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Text(
                            r['room_number'] ?? '?',
                            style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('Room ${r['room_number']}'),
                        subtitle: Text(
                            '${r['room_type'] ?? 'Standard'} Â· Floor ${r['floor'] ?? '-'}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${r['occupied'] ?? 0}/${r['capacity'] ?? 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            if (r['monthly_fee'] != null)
                              Text('\$${r['monthly_fee']}/mo',
                                  style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _allocTab() {
    return _allocations.isEmpty
        ? const Center(child: Text('No active allocations'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _allocations.length,
            itemBuilder: (_, i) {
              final a = _allocations[i];
              final date = a['allocated_at'] != null
                  ? DateTime.tryParse(a['allocated_at'])
                  : null;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(a['students']?['student_code'] ?? 'Student'),
                  subtitle: date != null
                      ? Text(
                          'Since ${date.toLocal().toString().substring(0, 10)}')
                      : null,
                  trailing: const Chip(label: Text('Active')),
                ),
              );
            },
          );
  }

  Future<void> _addRoomDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddRoomFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _load();
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
      );
}

class _AddRoomFormPage extends ConsumerStatefulWidget {
  const _AddRoomFormPage();

  @override
  ConsumerState<_AddRoomFormPage> createState() => _AddRoomFormPageState();
}

class _AddRoomFormPageState extends ConsumerState<_AddRoomFormPage> {
  final _sb = Supabase.instance.client;
  final _roomCtrl = TextEditingController();
  final _capCtrl = TextEditingController(text: '2');
  final _feeCtrl = TextEditingController();
  String _type = 'double';

  @override
  void dispose() {
    _roomCtrl.dispose();
    _capCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_roomCtrl.text.isEmpty) return;
    final tenantId = _sb.auth.currentUser?.userMetadata?['tenant_id'];
    await _sb.from('hostel_rooms').insert({
      'room_number': _roomCtrl.text,
      'capacity': int.tryParse(_capCtrl.text) ?? 2,
      'monthly_fee': double.tryParse(_feeCtrl.text),
      'room_type': _type,
      'status': 'available',
      if (tenantId != null) 'tenant_id': tenantId,
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(L.add, ref)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () { debugPrint('[hostel_screen] Save button CLICKED'); _save(); },
            child: Text(t(L.add, ref)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _roomCtrl,
              decoration: InputDecoration(labelText: t(LModule.library, ref)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _capCtrl,
              decoration: InputDecoration(labelText: t(LCrud.capacity, ref)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feeCtrl,
              decoration: InputDecoration(labelText: t(LPayment.amount, ref)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
initialValue: _type,
              decoration: InputDecoration(labelText: t(LColumn.cType, ref)),
              items: ['single', 'double', 'dormitory']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
          ],
        ),
      ),
    );
  }
}
