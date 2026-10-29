import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/l10n/locale_keys.dart';

class StaffITSupportScreen extends ConsumerStatefulWidget {
  const StaffITSupportScreen({super.key});
  @override
  ConsumerState<StaffITSupportScreen> createState() =>
      _StaffITSupportScreenState();
}

class _StaffITSupportScreenState extends ConsumerState<StaffITSupportScreen> {
  final _sb = Supabase.instance.client;
  bool _loading = true;
  int _openTickets = 0;
  List<Map<String, dynamic>> _tickets = [];

  static const _priorities = ['low', 'medium', 'high', 'critical'];
  static const _statuses = ['open', 'in_progress', 'resolved', 'closed'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final openCount = await _sb
          .from('support_tickets')
          .select('id')
          .eq('status', 'open');
      final tickets = await _sb
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        _openTickets = openCount.length;
        _tickets = List<Map<String, dynamic>>.from(tickets);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? ticket}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _TicketFormPage(
          ticket: ticket,
          priorities: _priorities,
          statuses: _statuses,
          statusLabel: _statusLabel,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != true) return;
    _loadData();
  }

  Future<void> _confirmDelete(Map<String, dynamic> ticket) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_ticket, ref)),
        content: Text('Delete "${ticket['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      await _sb.from('support_tickets').delete().eq('id', ticket['id']);
      _loadData();
    } catch (_) {}
  }

  Widget _ticketCard(Map<String, dynamic> ticket) {
    final theme = Theme.of(context);
    final priority = ticket['priority'] as String? ?? 'medium';
    final status = ticket['status'] as String? ?? 'open';

    return AppCard(
      pressable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket['title'] ?? '',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InfoBadge(
                label: priority[0].toUpperCase() + priority.substring(1),
                color: _priorityColor(priority),
              ),
              const SizedBox(width: AppSpacing.sm),
              InfoBadge(
                label: _statusLabel(status),
                color: _statusColor(status),
              ),
            ],
          ),
          if ((ticket['description'] as String?)?.isNotEmpty == true) ...[
            const VSpace(AppSpacing.sm),
            Text(
              ticket['description'],
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const VSpace(AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showAddEditDialog(ticket: ticket),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(t(L.edit, ref)),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _confirmDelete(ticket),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(t(L.delete, ref)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          const SectionHeader(
            title: 'IT Support',
            subtitle: 'Technical issues, software, and hardware',
            icon: Icons.computer_outlined,
          ),
          const VSpace(AppSpacing.lg),
          StatCard(
            title: 'Open Tickets',
            value: '$_openTickets',
            icon: Icons.confirmation_number_outlined,
          ),
          const VSpace(AppSpacing.lg),
          if (_tickets.isEmpty)
            EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No tickets',
              message: 'Create a support ticket to get started.',
              actionText: 'New Ticket',
              onAction: () => _showAddEditDialog(),
            )
          else
            ..._tickets.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ticketCard(t),
                )),
        ],
      ),
    );
  }
}

class _TicketFormPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? ticket;
  final List<String> priorities;
  final List<String> statuses;
  final String Function(String) statusLabel;

  const _TicketFormPage({
    this.ticket,
    required this.priorities,
    required this.statuses,
    required this.statusLabel,
  });

  @override
  ConsumerState<_TicketFormPage> createState() => _TicketFormPageState();
}

class _TicketFormPageState extends ConsumerState<_TicketFormPage> {
  final _sb = Supabase.instance.client;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _priority;
  late String _status;

  bool get _isEditing => widget.ticket != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.ticket?['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.ticket?['description'] ?? '');
    _priority = widget.ticket?['priority'] ?? 'medium';
    _status = widget.ticket?['status'] ?? 'open';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    try {
      if (_isEditing) {
        await _sb.from('support_tickets').update({
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'priority': _priority,
          'status': _status,
        }).eq('id', widget.ticket!['id']);
      } else {
        await _sb.from('support_tickets').insert({
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'priority': _priority,
          'status': _status,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Ticket' : 'New Ticket'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () { debugPrint('[staff_it_support_screen] Save button CLICKED'); _save(); },
            child: Text(_isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: widget.priorities
                  .map((p) => DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1))))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: widget.statuses
                  .map((s) => DropdownMenuItem(value: s, child: Text(widget.statusLabel(s))))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ),
    );
  }
}
