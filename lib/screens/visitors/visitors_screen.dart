import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});
  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _visitors = [];
  bool _loading = true;
  bool _showActive = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tenantId = _sb.auth.currentUser?.userMetadata?['tenant_id'];
      var q = _sb.from('visitors').select('*, users(full_name)');
      if (tenantId != null) q = q.eq('tenant_id', tenantId);
      if (_showActive) q = q.isFilter('check_out', null);
      final data = await q.order('check_in', ascending: false).limit(100);
      setState(() {
        _visitors = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkOut(String id) async {
    await _sb.from('visitors').update(
        {'check_out': DateTime.now().toIso8601String()}).eq('id', id);
    setState(() => _loading = true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t(LAll.all_visitor_management, ref)),
        actions: [
          Row(
            children: [
              Text(t(LAll.all_active_only, ref),
                  style: theme.textTheme.bodySmall),
              Switch(
                value: _showActive,
                onChanged: (v) {
                  setState(() {
                    _showActive = v;
                    _loading = true;
                  });
                  _load();
                },
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const PageSkeleton(type: 'list')
          : _visitors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 64, color: theme.colorScheme.outline),
                      const SizedBox(height: 16),
                      Text(t(LAll.all_no_visitors_found, ref),
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _visitors.length,
                  itemBuilder: (_, i) {
                    final v = _visitors[i];
                    final checkIn = v['check_in'] != null
                        ? DateTime.tryParse(v['check_in'])
                        : null;
                    final checkOut = v['check_out'] != null
                        ? DateTime.tryParse(v['check_out'])
                        : null;
                    final isActive = checkOut == null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.blue.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            color: isActive
                                ? Colors.blue
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        title: Text(v['name'] ?? 'Unknown'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (v['purpose'] != null)
                              Text(v['purpose'],
                                  style: theme.textTheme.bodySmall),
                            if (v['users']?['full_name'] != null)
                              Text('Host: ${v['users']['full_name']}',
                                  style: theme.textTheme.bodySmall),
                            if (checkIn != null)
                              Text(
                                  'In: ${checkIn.toLocal().toString().substring(0, 16)}',
                                  style: theme.textTheme.bodySmall),
                            if (checkOut != null)
                              Text(
                                  'Out: ${checkOut.toLocal().toString().substring(0, 16)}',
                                  style: theme.textTheme.bodySmall),
                          ],
                        ),
                        trailing: isActive
                            ? FilledButton.tonal(
                                onPressed: () => _checkOut(v['id']),
                                child: Text(t(LAll.all_check_out, ref)),
                              )
                            : Chip(
                                label: Text(t(LAll.all_left, ref)),
                                backgroundColor: theme
                                    .colorScheme.surfaceContainerHighest,
                              ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkInDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _checkInDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final idNumCtrl = TextEditingController();
    String idType = 'national_id';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(t(LAll.all_visitor_checkin, ref)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Visitor Name')),
              const SizedBox(height: 8),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(labelText: 'Purpose')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
initialValue: idType,
                decoration: const InputDecoration(labelText: 'ID Type'),
                items: ['national_id', 'passport', 'driving_license']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setSt(() => idType = v ?? idType),
              ),
              const SizedBox(height: 8),
              TextField(
                  controller: idNumCtrl,
                  decoration: const InputDecoration(labelText: 'ID Number')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(t(L.cancel, ref))),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) return;
                final tenantId =
                    _sb.auth.currentUser?.userMetadata?['tenant_id'];
                await _sb.from('visitors').insert({
                  'name': nameCtrl.text,
                  'phone': phoneCtrl.text.isEmpty ? null : phoneCtrl.text,
                  'purpose':
                      purposeCtrl.text.isEmpty ? null : purposeCtrl.text,
                  'id_type': idType,
                  'id_number':
                      idNumCtrl.text.isEmpty ? null : idNumCtrl.text,
                  'check_in': DateTime.now().toIso8601String(),
                  if (tenantId != null) 'tenant_id': tenantId,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() => _loading = true);
                _load();
              },
              child: Text(t(LAll.all_check_in, ref)),
            ),
          ],
        ),
      ),
    );
  }
}
