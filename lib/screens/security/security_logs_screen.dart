import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/widgets/skeleton_loader.dart';

class SecurityLogsScreen extends StatefulWidget {
  const SecurityLogsScreen({super.key});
  @override
  State<SecurityLogsScreen> createState() => _SecurityLogsScreenState();
}

class _SecurityLogsScreenState extends State<SecurityLogsScreen> {
  final _sb = Supabase.instance.client;
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final tenantId = _sb.auth.currentUser?.userMetadata?['tenant_id'];
      var q = _sb.from('security_logs').select('*, users(full_name)');
      if (tenantId != null) q = q.eq('tenant_id', tenantId);
      if (_filter != 'all') q = q.eq('log_type', _filter);
      final data = await q.order('created_at', ascending: false).limit(100);
      setState(() {
        _logs = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  IconData _logIcon(String? type) {
    switch (type) {
      case 'entry':
        return Icons.login;
      case 'exit':
        return Icons.logout;
      case 'incident':
        return Icons.warning_amber;
      case 'visitor':
        return Icons.person_add;
      default:
        return Icons.security;
    }
  }

  Color _logColor(String? type) {
    switch (type) {
      case 'entry':
        return Colors.blue;
      case 'exit':
        return Colors.blue;
      case 'incident':
        return Colors.red;
      case 'visitor':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: ['all', 'entry', 'exit', 'incident', 'visitor']
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(s[0].toUpperCase() + s.substring(1)),
                          selected: _filter == s,
                          onSelected: (_) {
                            setState(() {
                              _filter = s;
                              _loading = true;
                            });
                            _load();
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const PageSkeleton(type: 'list')
                : _logs.isEmpty
                    ? const Center(child: Text('No security logs found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _logs.length,
                        itemBuilder: (_, i) {
                          final log = _logs[i];
                          final color = _logColor(log['log_type']);
                          final dt = log['created_at'] != null
                              ? DateTime.tryParse(log['created_at'])
                              : null;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(_logIcon(log['log_type']),
                                    color: color, size: 20),
                              ),
                              title: Text(
                                log['person_name'] ??
                                    log['users']?['full_name'] ??
                                    'Unknown',
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log['log_type']?.toUpperCase() ?? 'LOG',
                                      style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11)),
                                  if (log['notes'] != null)
                                    Text(log['notes'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                ],
                              ),
                              trailing: dt != null
                                  ? Text(
                                      dt
                                          .toLocal()
                                          .toString()
                                          .substring(0, 16),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addLogDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addLogDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const _AddSecurityLogFormPage(),
        fullscreenDialog: true,
      ),
    );
    if (result == true) {
      setState(() => _loading = true);
      _load();
    }
  }
}

class _AddSecurityLogFormPage extends StatefulWidget {
  const _AddSecurityLogFormPage();

  @override
  State<_AddSecurityLogFormPage> createState() => _AddSecurityLogFormPageState();
}

class _AddSecurityLogFormPageState extends State<_AddSecurityLogFormPage> {
  final _sb = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _logType = 'entry';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) return;
    final tenantId = _sb.auth.currentUser?.userMetadata?['tenant_id'];
    final loggedBy = _sb.auth.currentUser?.id;
    await _sb.from('security_logs').insert({
      'log_type': _logType,
      'person_name': _nameCtrl.text,
      'notes': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      if (loggedBy != null) 'logged_by': loggedBy,
      if (tenantId != null) 'tenant_id': tenantId,
    });
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Security Log'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () { debugPrint('[security_logs_screen] Save button CLICKED'); _save(); },
            child: const Text('Add'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
initialValue: _logType,
              decoration: const InputDecoration(labelText: 'Log Type'),
              items: ['entry', 'exit', 'incident', 'visitor']
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _logType = v ?? _logType),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Person Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
