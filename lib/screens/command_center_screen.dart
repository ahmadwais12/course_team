import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/l10n/locale_keys.dart';
import 'package:course_emis/theme.dart';
import 'package:course_emis/widgets/ui_helpers.dart';
import 'package:course_emis/widgets/motion.dart';

class CommandCenterScreen extends ConsumerStatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  ConsumerState<CommandCenterScreen> createState() =>
      _CommandCenterScreenState();
}

class _CommandCenterScreenState extends ConsumerState<CommandCenterScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _alerts = [];
  int _activeAlerts = 0;
  int _totalAlerts = 0;
  int _resolvedToday = 0;
  int _criticalIssues = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _supabase
          .from('alerts')
          .select()
          .order('created_at', ascending: false);

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day).toIso8601String();

      final activeCount =
          alerts.where((a) => a['status'] == 'active').length;
      final resolvedCount = alerts
          .where((a) =>
              a['status'] == 'resolved' &&
              (a['created_at'] as String).compareTo(todayStart) >= 0)
          .length;
      final criticalCount =
          alerts.where((a) => a['severity'] == 'critical').length;

      setState(() {
        _alerts = List<Map<String, dynamic>>.from(alerts);
        _activeAlerts = activeCount;
        _totalAlerts = alerts.length;
        _resolvedToday = resolvedCount;
        _criticalIssues = criticalCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_failed_to_load_data_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.red;
      case 'acknowledged':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> _showAlertDialog({Map<String, dynamic>? alert}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _AlertDialogPage(alert: alert),
        fullscreenDialog: true,
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _confirmDelete(Map<String, dynamic> alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t(LAll.all_delete_alert, ref)),
        content: Text('Delete "${alert['title']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t(L.cancel, ref)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(t(L.delete, ref)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase.from('alerts').delete().eq('id', alert['id']);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  Future<void> _acknowledgeAlert(Map<String, dynamic> alert) async {
    try {
      await _supabase
          .from('alerts')
          .update({'status': 'acknowledged'}).eq('id', alert['id']);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(LTitle.commandCenter, ref))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAlertDialog(),
        tooltip: 'Add Alert',
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Real-time Monitoring',
                      subtitle: 'Status, alerts, and remote actions',
                      icon: Icons.dashboard_customize_outlined,
                    ),
                    const VSpace(AppSpacing.lg),
                    Wrap(
                      runSpacing: AppSpacing.md,
                      spacing: AppSpacing.md,
                      children: [
                        SizedBox(
                          width: 320,
                          child: StatCard(
                            title: 'Active Alerts',
                            value: _activeAlerts.toString(),
                            icon: Icons.notifications_active_outlined,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: StatCard(
                            title: 'Total Alerts',
                            value: _totalAlerts.toString(),
                            icon: Icons.notifications_outlined,
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: StatCard(
                            title: 'Resolved Today',
                            value: _resolvedToday.toString(),
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(
                          width: 320,
                          child: StatCard(
                            title: 'Critical Issues',
                            value: _criticalIssues.toString(),
                            icon: Icons.error_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const VSpace(AppSpacing.lg),
                    FadeSlide(
                      child: SectionHeader(
                        title: 'Alerts',
                        subtitle: '${_alerts.length} alert(s)',
                        icon: Icons.campaign_outlined,
                        action: IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh_outlined),
                          tooltip: 'Refresh',
                        ),
                      ),
                    ),
                    const VSpace(AppSpacing.md),
                    if (_alerts.isEmpty)
                      AppCard(
                        pressable: false,
                        child: EmptyState(
                          icon: Icons.notifications_off_outlined,
                          title: 'No Alerts',
                          message: 'No alerts have been created yet.',
                          actionText: 'Create Alert',
                          onAction: () => _showAlertDialog(),
                        ),
                      )
                    else
                      ...List.generate(_alerts.length, (i) {
                        final alert = _alerts[i];
                        final severity =
                            (alert['severity'] as String?) ?? 'info';
                        final status =
                            (alert['status'] as String?) ?? 'active';
                        final sevColor = _severityColor(severity);
                        final isAcknowledged = status == 'acknowledged';
                        final isResolved = status == 'resolved';

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AnimatedListItem(
                            index: i,
                            child: AppCard(
                              pressable: false,
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: sevColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _severityIcon(severity),
                                    color: sevColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  alert['title'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall,
                                ),
                                subtitle: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4),
                                  child: Text(
                                    alert['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status)
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(
                                                AppRadius.sm),
                                      ),
                                      child: Text(
                                        status[0].toUpperCase() +
                                            status.substring(1),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatTime(
                                          alert['created_at'] ?? ''),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    if (!isAcknowledged &&
                                        !isResolved) ...[
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed: () =>
                                            _acknowledgeAlert(alert),
                                        icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 20),
                                        tooltip: 'Acknowledge',
                                        color: Colors.orange,
                                        constraints:
                                            const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36),
                                      ),
                                    ],
                                    if (!isResolved) ...[
                                      IconButton(
                                        onPressed: () =>
                                            _showAlertDialog(
                                                alert: alert),
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20),
                                        tooltip: 'Edit',
                                        constraints:
                                            const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _confirmDelete(alert),
                                        icon: const Icon(
                                            Icons.delete_outline,
                                            size: 20),
                                        tooltip: 'Delete',
                                        color: Colors.red,
                                        constraints:
                                            const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AlertDialogPage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? alert;
  const _AlertDialogPage({this.alert});

  @override
  ConsumerState<_AlertDialogPage> createState() => _AlertDialogPageState();
}

class _AlertDialogPageState extends ConsumerState<_AlertDialogPage> {
  final _supabase = Supabase.instance.client;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late String _severity;
  late String _status;

  bool get _isEdit => widget.alert != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.alert?['title'] ?? '');
    _descCtrl = TextEditingController(text: widget.alert?['description'] ?? '');
    _severity = widget.alert?['severity'] ?? 'info';
    _status = widget.alert?['status'] ?? 'active';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Alert' : 'New Alert'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t(L.cancel, ref)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Enter alert title',
            ),
          ),
          const VSpace(AppSpacing.md),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter alert description',
            ),
            maxLines: 3,
          ),
          const VSpace(AppSpacing.md),
          DropdownButtonFormField<String>(
initialValue: _severity,
            decoration: const InputDecoration(labelText: 'Severity'),
            items: [
              DropdownMenuItem(value: 'info', child: Text(t(LAll.all_info, ref))),
              DropdownMenuItem(value: 'warning', child: Text(t(LAll.all_warning, ref))),
              DropdownMenuItem(value: 'critical', child: Text(t(LAll.all_critical, ref))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _severity = v);
            },
          ),
          const VSpace(AppSpacing.md),
          DropdownButtonFormField<String>(
initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              DropdownMenuItem(value: 'active', child: Text(t(LCrud.active, ref))),
              DropdownMenuItem(value: 'acknowledged', child: Text(t(LAll.all_acknowledged, ref))),
              DropdownMenuItem(value: 'resolved', child: Text(t(LStatus.resolved, ref))),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _status = v);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { debugPrint('[command_center_screen] Save button CLICKED'); _save(); },
            child: Text(_isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    try {
      if (_isEdit) {
        await _supabase.from('alerts').update({
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'severity': _severity,
          'status': _status,
        }).eq('id', widget.alert!['id']);
      } else {
        await _supabase.from('alerts').insert({
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'severity': _severity,
          'status': _status,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tt(LAll.all_error_x, ref, [e.toString()]))),
        );
      }
    }
  }
}
